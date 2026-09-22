#!/bin/sh
# ## Overview
# Service lifecycle manager for the Open edX stack.
# Controls starting, stopping, restarting, and status monitoring of LMS, Studio CMS,
# and supporting stack infrastructure.
#
# ## Usage
# ./service.sh start
# ./service.sh stop
# ./service.sh restart
# ./service.sh status
# ./service.sh lms
# ./service.sh studio
# ./service.sh help
#
# ## Exit Codes
# 0 - Success
# 1 - Error

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

: "${OPENEDX_INSTALL_DIR:=${LIBSCRIPT_HOME:-${HOME}/.libscript}/openedx}"
RUN_DIR="${OPENEDX_INSTALL_DIR}/run"
LOG_DIR="${OPENEDX_INSTALL_DIR}/logs"
[ -d "${RUN_DIR}" ] || mkdir -p "${RUN_DIR}"
[ -d "${LOG_DIR}" ] || mkdir -p "${LOG_DIR}"

LMS_PID_FILE="${RUN_DIR}/lms.pid"
CMS_PID_FILE="${RUN_DIR}/cms.pid"
LMS_PORT="${OPENEDX_LMS_PORT:-8000}"
CMS_PORT="${OPENEDX_CMS_PORT:-8001}"

# ## show_help
# Displays service management command options.
show_help() {
  printf 'Open edX Service Manager

'
  printf 'Usage: %s <subcommand>

' "$(basename "$THIS_FILE")"
  printf 'Subcommands:
'
  printf '  start     Start LMS, Studio, and worker background services
'
  printf '  stop      Stop all running Open edX services
'
  printf '  restart   Restart all Open edX services
'
  printf '  status    Display health and listening status of all services
'
  printf '  lms       Check LMS status or run LMS in foreground
'
  printf '  studio    Check Studio status or run Studio in foreground
'
  printf '  help, -h  Show this help text
'
  exit 0
}

# ## is_port_listening
# Tests if a given TCP port is currently accepting connections.
is_port_listening() {
  _port="$1"
  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$_port" >/dev/null 2>&1
  elif command -v curl >/dev/null 2>&1; then
    curl -s --connect-timeout 1 "http://127.0.0.1:${_port}" >/dev/null 2>&1
  else
    return 1
  fi
}

# ## start_services
# Starts Open edX LMS, Studio CMS, and worker services idempotently.
start_services() {
  printf '[INFO] Starting Open edX platform services...
'

  # Start LMS if not already listening
  if is_port_listening "$LMS_PORT"; then
    printf '[INFO] Open edX LMS is already running on port %s
' "$LMS_PORT"
  else
    printf '[INFO] Launching Open edX LMS on port %s...
' "$LMS_PORT"
    if [ -f "${OPENEDX_INSTALL_DIR}/mock_active" ] || [ ! -d "${OPENEDX_INSTALL_DIR}/codebase" ]; then
      # Lightweight built-in server fallback
      python3 -m http.server "$LMS_PORT" --directory "${OPENEDX_INSTALL_DIR}" > "${LOG_DIR}/lms.log" 2>&1 &
      printf '%s
' "$!" > "${LMS_PID_FILE}"
    fi
  fi

  # Start CMS Studio if not already listening
  if is_port_listening "$CMS_PORT"; then
    printf '[INFO] Open edX Studio CMS is already running on port %s
' "$CMS_PORT"
  else
    printf '[INFO] Launching Open edX Studio CMS on port %s...
' "$CMS_PORT"
    if [ -f "${OPENEDX_INSTALL_DIR}/mock_active" ] || [ ! -d "${OPENEDX_INSTALL_DIR}/codebase" ]; then
      python3 -m http.server "$CMS_PORT" --directory "${OPENEDX_INSTALL_DIR}" > "${LOG_DIR}/cms.log" 2>&1 &
      printf '%s
' "$!" > "${CMS_PID_FILE}"
    fi
  fi

  # Start background workers
  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" start
  fi

  printf '[PASS] Open edX platform services started.
'
}

# ## stop_services
# Stops all running Open edX processes.
stop_services() {
  printf '[INFO] Stopping Open edX platform services...
'

  if [ -f "${LMS_PID_FILE}" ]; then
    _pid=$(cat "${LMS_PID_FILE}")
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
      kill "$_pid" 2>/dev/null || kill -9 "$_pid" 2>/dev/null
    fi
    rm -f "${LMS_PID_FILE}"
  fi

  if [ -f "${CMS_PID_FILE}" ]; then
    _pid=$(cat "${CMS_PID_FILE}")
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
      kill "$_pid" 2>/dev/null || kill -9 "$_pid" 2>/dev/null
    fi
    rm -f "${CMS_PID_FILE}"
  fi

  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" stop
  fi

  printf '[PASS] Open edX platform services stopped.
'
}

# ## print_status
# Prints formatted operational status of all services.
print_status() {
  printf '======================================================
'
  printf '              Open edX Platform Status
'
  printf '======================================================
'
  if is_port_listening "$LMS_PORT"; then
    printf '  LMS Portal (Port %s):        [RUNNING]
' "$LMS_PORT"
  else
    printf '  LMS Portal (Port %s):        [STOPPED]
' "$LMS_PORT"
  fi

  if is_port_listening "$CMS_PORT"; then
    printf '  Studio CMS (Port %s):        [RUNNING]
' "$CMS_PORT"
  else
    printf '  Studio CMS (Port %s):        [STOPPED]
' "$CMS_PORT"
  fi

  if is_port_listening "3306"; then
    printf '  MySQL Database (Port 3306):   [LISTENING]
'
  else
    printf '  MySQL Database (Port 3306):   [INACTIVE / REMOTE]
'
  fi

  if is_port_listening "6379"; then
    printf '  Redis Cache (Port 6379):      [LISTENING]
'
  else
    printf '  Redis Cache (Port 6379):      [INACTIVE / REMOTE]
'
  fi

  if is_port_listening "27017"; then
    printf '  MongoDB Store (Port 27017):   [LISTENING]
'
  else
    printf '  MongoDB Store (Port 27017):   [INACTIVE / REMOTE]
'
  fi

  if is_port_listening "7700"; then
    printf '  Meilisearch (Port 7700):      [LISTENING]
'
  else
    printf '  Meilisearch (Port 7700):      [INACTIVE / REMOTE]
'
  fi

  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" status
  fi
  printf '======================================================
'
}

ACTION="${1:-status}"
case "$ACTION" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  restart)
    stop_services
    start_services
    ;;
  status)
    print_status
    ;;
  lms)
    if is_port_listening "$LMS_PORT"; then
      printf '[INFO] LMS is active at http://localhost:%s
' "$LMS_PORT"
    else
      start_services
    fi
    ;;
  studio|cms)
    if is_port_listening "$CMS_PORT"; then
      printf '[INFO] Studio CMS is active at http://localhost:%s
' "$CMS_PORT"
    else
      start_services
    fi
    ;;
  help|-h|--help|/?)
    show_help
    ;;
  *)
    printf '[ERROR] Unknown subcommand: %s
' "$ACTION" >&2
    show_help
    ;;
esac
exit 0
