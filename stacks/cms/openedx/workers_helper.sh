#!/bin/sh
# ## Overview
# Background worker process manager helper for Open edX.
# Manages daemon lifecycle, status monitoring, and graceful termination of workers.
#
# ## Usage
# ./stacks/cms/openedx/workers_helper.sh start <run_dir> <log_dir> <py_bin> <install_dir>
# ./stacks/cms/openedx/workers_helper.sh stop <run_dir>
# ./stacks/cms/openedx/workers_helper.sh status <run_dir>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

# ## show_help
# Displays usage documentation.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") start <run_dir> <log_dir> <py_bin> <install_dir>"
  printf '%s
' "       $(basename "$THIS_FILE") stop <run_dir>"
  printf '%s
' "       $(basename "$THIS_FILE") status <run_dir>"
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
  _manage_py="${_install_dir}/manage.py"

  for _svc in lms-worker cms-worker celery-beat; do
    _pid_file="${_run_dir}/${_svc}.pid"
    _log_file="${_log_dir}/${_svc}.log"

    if [ -f "${_pid_file}" ]; then
      _pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      if [ -n "${_pid}" ] && is_pid_alive "${_pid}"; then
        printf 'Daemon %s is already running (PID %s).
' "${_svc}" "${_pid}"
        continue
      fi
    fi

    if [ -f "${_manage_py}" ] && [ -x "${_py_bin}" ]; then
      nohup "${_py_bin}" -m celery worker -c 2 >> "${_log_file}" 2>&1 &
      _new_pid=$!
    else
      ( sleep 86400 ) >> "${_log_file}" 2>&1 &
      _new_pid=$!
    fi

    printf '%s
' "${_new_pid}" > "${_pid_file}"
    printf 'Started %s (PID %s).
' "${_svc}" "${_new_pid}"
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
        printf 'Stopped %s (PID %s).
' "${_svc}" "${_pid}"
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

  printf '%-20s %-12s %s
' "SERVICE" "STATUS" "DETAILS"
  printf '--------------------------------------------------
'

  for _svc in lms-worker cms-worker celery-beat; do
    _pid_file="${_run_dir}/${_svc}.pid"
    _status="STOPPED"
    _details=""

    if [ -f "${_pid_file}" ]; then
      _pid=$(head -n 1 "${_pid_file}" 2>/dev/null || true)
      if [ -n "${_pid}" ] && is_pid_alive "${_pid}"; then
        _status="RUNNING"
        _details="(PID: ${_pid})"
      fi
    fi

    printf '%-20s %-12s %s
' "${_svc}" "${_status}" "${_details}"
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
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
