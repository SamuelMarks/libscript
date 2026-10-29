#!/bin/sh
# ## Overview
# Background worker process manager helper for Open edX.
# Manages daemon lifecycle, status monitoring, and graceful termination of workers.
#
# ## Usage
# ./_lib/web-apps/openedx/workers_helper.sh start <run_dir> <log_dir> <py_bin> <install_dir>
# ./_lib/web-apps/openedx/workers_helper.sh stop <run_dir>
# ./_lib/web-apps/openedx/workers_helper.sh status <run_dir>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## show_help
# Displays usage documentation.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") start <run_dir> <log_dir> <py_bin> <install_dir>"
  printf '%s\n' "       $(basename "$THIS_FILE") stop <run_dir>"
  printf '%s\n' "       $(basename "$THIS_FILE") status <run_dir>"
  exit 0
}

# ## is_pid_alive
# Checks whether a given PID is currently active.
#
# Inputs:
#   $1 - Process ID
is_pid_alive() {
  _pid="$1"
  kill -0 "${_pid}" 2>/dev/null
}

# ## do_start
# Starts background Celery worker daemons and records PID files.
#
# Inputs:
#   $1 - Run directory for PID files
#   $2 - Log directory
#   $3 - Python executable
#   $4 - Installation directory
do_start() {
  _run_dir="$1"
  _log_dir="$2"
  _py_bin="$3"
  _install_dir="$4"

  mkdir -p "${_run_dir}" "${_log_dir}"
  _codebase="${_install_dir}/codebase"
  if [ ! -f "${_codebase}/manage.py" ] && [ -f "${_install_dir}/manage.py" ]; then
    _codebase="${_install_dir}"
  fi

  for _svc in lms-worker cms-worker celery-beat; do
    _pid_file="${_run_dir}/${_svc}.pid"
    _log_file="${_log_dir}/${_svc}.log"

    if [ -f "${_pid_file}" ]; then
      _pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      if [ -n "${_pid}" ] && is_pid_alive "${_pid}"; then
        printf 'Daemon %s is already running (PID %s).\n' "${_svc}" "${_pid}"
        continue
      fi
    fi

    if [ -x "${_py_bin}" ] && "${_py_bin}" -c "import celery" >/dev/null 2>&1; then
      export PYTHONPATH="${_codebase}"
      export LMS_CFG="${_install_dir}/config/lms.yml"
      export CMS_CFG="${_install_dir}/config/cms.yml"
      export STUDIO_CFG="${_install_dir}/config/cms.yml"
      export REVISION_CFG="${_install_dir}/config/revisions.yml"
      case "${_svc}" in
        lms-worker)
          (cd "${_codebase}" 2>/dev/null || true; SERVICE_VARIANT="lms" DJANGO_SETTINGS_MODULE="lms.envs.production" nohup "${_py_bin}" -m celery --app=lms.celery worker --loglevel=info --concurrency=4 --hostname=edx.lms.core.default.%h --queues=edx.lms.core.default,edx.lms.core.high,edx.lms.core.high_mem --prefetch-multiplier=1 --without-gossip --without-mingle >> "${_log_file}" 2>&1 & printf '%s\n' "$!" > "${_pid_file}")
          ;;
        cms-worker)
          (cd "${_codebase}" 2>/dev/null || true; SERVICE_VARIANT="cms" DJANGO_SETTINGS_MODULE="cms.envs.production" nohup "${_py_bin}" -m celery --app=cms.celery worker --loglevel=info --concurrency=2 --hostname=edx.cms.core.default.%h --queues=edx.cms.core.default,edx.cms.core.high,edx.cms.core.low --prefetch-multiplier=1 --without-gossip --without-mingle >> "${_log_file}" 2>&1 & printf '%s\n' "$!" > "${_pid_file}")
          ;;
        celery-beat)
          (cd "${_codebase}" 2>/dev/null || true; SERVICE_VARIANT="lms" DJANGO_SETTINGS_MODULE="lms.envs.production" nohup "${_py_bin}" -m celery --app=lms.celery beat --loglevel=info --pidfile="${_pid_file}" --schedule="${_run_dir}/celerybeat-schedule" >> "${_log_file}" 2>&1 & printf '%s\n' "$!" > "${_pid_file}")
          ;;
      esac
      _new_pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      printf 'Started %s (PID %s).\n' "${_svc}" "${_new_pid}"
    else
      printf '[WARN] Celery package or Python runtime not installed at %s; skipping worker %s.\n' "${_py_bin}" "${_svc}" >&2
    fi
  done
}

# ## do_stop
# Terminates running worker daemons and cleans up PID files.
#
# Inputs:
#   $1 - Run directory
do_stop() {
  _run_dir="$1"

  for _svc in lms-worker cms-worker celery-beat; do
    _pid_file="${_run_dir}/${_svc}.pid"
    if [ -f "${_pid_file}" ]; then
      _pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      if [ -n "${_pid}" ]; then
        kill -15 "${_pid}" 2>/dev/null || kill -9 "${_pid}" 2>/dev/null || true
        printf 'Stopped %s (PID %s).\n' "${_svc}" "${_pid}"
      fi
      rm -f "${_pid_file}"
    fi
  done
}

# ## do_status
# Displays tabular status report of worker daemons.
#
# Inputs:
#   $1 - Run directory
do_status() {
  _run_dir="$1"

  printf '%-20s %-12s %s\n' "SERVICE" "STATUS" "DETAILS"
  printf '%s\n' '--------------------------------------------------'

  for _svc in lms-worker cms-worker celery-beat; do
    _pid_file="${_run_dir}/${_svc}.pid"
    _status='STOPPED'
    _details=""

    if [ -f "${_pid_file}" ]; then
      _pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      if [ -n "${_pid}" ] && is_pid_alive "${_pid}"; then
        _status='RUNNING'
        _details="(PID: ${_pid})"
      fi
    fi

    printf '%-20s %-12s %s\n' "${_svc}" "${_status}" "${_details}"
  done
}

# ## main
# Main entrypoint parsing action commands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    start)
      if [ $# -lt 4 ]; then show_help; fi
      do_start "$1" "$2" "$3" "$4"
      ;;
    stop)
      if [ $# -lt 1 ]; then show_help; fi
      do_stop "$1"
      ;;
    status)
      if [ $# -lt 1 ]; then show_help; fi
      do_status "$1"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s\n' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
