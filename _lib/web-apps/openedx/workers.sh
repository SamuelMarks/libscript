#!/bin/sh
# ## Overview
# Background worker and Celery beat scheduler management utility for Open edX.
#
# ## Usage
# ./workers.sh <start|stop|restart|status|help>

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

if [ -f "${DIR}/env.sh" ]; then
  SCRIPT_NAME="${DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
RUN_DIR="${OPENEDX_INSTALL_DIR}/run"
LOG_DIR="${OPENEDX_INSTALL_DIR}/logs"
PYTHON_BIN="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
WORKERS_HELPER="${SCRIPT_DIR}/workers_helper.sh"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

# ## resolve_python
# Resolves the Python executable for worker execution.
resolve_python() {
  if [ -x "${PYTHON_BIN}" ]; then
    printf '%s\n' "${PYTHON_BIN}"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf 'python3\n'
  fi
}

# ## workers_start
# Starts all workers via workers_helper.sh.
workers_start() {
  log_info 'Starting Open edX Celery workers and scheduler...'
  _py="$(resolve_python)"
  "${WORKERS_HELPER}" start "${RUN_DIR}" "${LOG_DIR}" "${_py}" "${OPENEDX_INSTALL_DIR}"
  log_success "All Open edX background workers started."
}

# ## workers_stop
# Stops all workers via workers_helper.sh.
workers_stop() {
  log_info 'Stopping Open edX Celery workers and scheduler...'
  "${WORKERS_HELPER}" stop "${RUN_DIR}"
  log_success "All Open edX background workers stopped."
}

# ## workers_status
# Displays status report for workers via workers_helper.sh.
workers_status() {
  printf '======================================================\n'
  printf '             Open edX Background Workers Status        \n'
  printf '======================================================\n'
  "${WORKERS_HELPER}" status "${RUN_DIR}"
  printf '======================================================\n'
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Worker & Scheduler Management CLI

Usage:
  $0 start
  $0 stop
  $0 restart
  $0 status
  $0 help

Commands:
  start     Launch background worker and beat daemons
  stop      Stop running worker daemons
  restart   Restart worker daemons
  status    Check status of all workers
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  start)
    workers_start
    ;;
  stop)
    workers_stop
    ;;
  restart)
    workers_stop
    workers_start
    ;;
  status)
    workers_status
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown worker command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
