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
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
APP_DIR="${SCRIPT_DIR}"
export APP_DIR
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

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
  printf 'Subcommands:\n'
  printf '  start     Start LMS, Studio, and worker background services\n'
  printf '  stop      Stop all running Open edX services\n'
  printf '  restart   Restart all Open edX services\n'
  printf '  status    Display health and listening status of all services\n'
  printf '  lms       Check LMS status or run LMS in foreground\n'
  printf '  studio    Check Studio status or run Studio in foreground\n'
  printf '  help, -h  Show this help text\n'
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
  printf '[INFO] Starting Open edX platform services...\n'

  _codebase="${OPENEDX_INSTALL_DIR}/codebase"
  if [ ! -f "${_codebase}/manage.py" ] && [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
    _codebase="${OPENEDX_INSTALL_DIR}"
  fi
  _py="python3"
  if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ]; then
    _py="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
  fi

  # Start LMS if not already listening
  if is_port_listening "$LMS_PORT"; then
    printf '[INFO] Open edX LMS is already running on port %s\n' "$LMS_PORT"
  else
    printf '[INFO] Launching Open edX LMS on port %s...\n' "$LMS_PORT"
    if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn" ] && [ -f "${_codebase}/manage.py" ]; then
      (cd "${_codebase}" && "${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn" --bind "0.0.0.0:${LMS_PORT}" --workers 4 lms.wsgi:application < /dev/null > "${LOG_DIR}/lms.log" 2>&1 & printf '%s\n' "$!" > "${LMS_PID_FILE}")
    elif [ -f "${_codebase}/manage.py" ]; then
      (cd "${_codebase}" && nohup "${_py}" manage.py lms --settings=libscript runserver --insecure "0.0.0.0:${LMS_PORT}" --noreload < /dev/null > "${LOG_DIR}/lms.log" 2>&1 & printf '%s\n' "$!" > "${LMS_PID_FILE}")
    else
      printf '[ERROR] Real Open edX codebase (manage.py) not found at %s.\n' "${_codebase}" >&2
      exit 1
    fi
  fi

  # Start CMS Studio if not already listening
  if is_port_listening "$CMS_PORT"; then
    printf '[INFO] Open edX Studio CMS is already running on port %s\n' "$CMS_PORT"
  else
    printf '[INFO] Launching Open edX Studio CMS on port %s...\n' "$CMS_PORT"
    if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn" ] && [ -f "${_codebase}/manage.py" ]; then
      (cd "${_codebase}" && "${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn" --bind "0.0.0.0:${CMS_PORT}" --workers 2 cms.wsgi:application < /dev/null > "${LOG_DIR}/cms.log" 2>&1 & printf '%s\n' "$!" > "${CMS_PID_FILE}")
    elif [ -f "${_codebase}/manage.py" ]; then
      (cd "${_codebase}" && nohup "${_py}" manage.py cms --settings=libscript runserver --insecure "0.0.0.0:${CMS_PORT}" --noreload < /dev/null > "${LOG_DIR}/cms.log" 2>&1 & printf '%s\n' "$!" > "${CMS_PID_FILE}")
    else
      printf '[ERROR] Real Open edX codebase (manage.py) not found at %s.\n' "${_codebase}" >&2
      exit 1
    fi
  fi

  # Start background workers
  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" start
  fi

  printf '[INFO] Waiting for LMS and CMS to become responsive...\n'
  _timeout=30
  _count=0
  while [ $_count -lt $_timeout ]; do
    if is_port_listening "$LMS_PORT" && is_port_listening "$CMS_PORT"; then
      printf '[PASS] Open edX platform services started and listening.\n'
      return 0
    fi
    sleep 2
    _count=$((_count + 2))
  done

  printf '[ERROR] Timeout waiting for Open edX services to start listening.\n' >&2
  return 1
}

# ## stop_services
# Stops all running Open edX processes.
stop_services() {
  printf '[INFO] Stopping Open edX platform services...\n'

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

  printf '[PASS] Open edX platform services stopped.\n'
}

# ## print_status
# Prints formatted operational status of all services.
print_status() {
  printf '======================================================\n'
  printf '              Open edX Platform Status\n'
  printf '======================================================\n'
  if is_port_listening "$LMS_PORT"; then
    printf '  LMS Portal (Port %s):        [RUNNING]\n' "$LMS_PORT"
  else
    printf '  LMS Portal (Port %s):        [STOPPED]\n' "$LMS_PORT"
  fi

  if is_port_listening "$CMS_PORT"; then
    printf '  Studio CMS (Port %s):        [RUNNING]\n' "$CMS_PORT"
  else
    printf '  Studio CMS (Port %s):        [STOPPED]\n' "$CMS_PORT"
  fi

  if is_port_listening "3306"; then
    printf '  MySQL Database (Port 3306):   [LISTENING]\n'
  else
    printf '  MySQL Database (Port 3306):   [INACTIVE / REMOTE]\n'
  fi

  if is_port_listening "6379"; then
    printf '  Redis Cache (Port 6379):      [LISTENING]\n'
  else
    printf '  Redis Cache (Port 6379):      [INACTIVE / REMOTE]\n'
  fi

  if is_port_listening "27017"; then
    printf '  MongoDB Store (Port 27017):   [LISTENING]\n'
  else
    printf '  MongoDB Store (Port 27017):   [INACTIVE / REMOTE]\n'
  fi

  if is_port_listening "7700"; then
    printf '  Meilisearch (Port 7700):      [LISTENING]\n'
  else
    printf '  Meilisearch (Port 7700):      [INACTIVE / REMOTE]\n'
  fi

  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" status
  fi
  printf '======================================================\n'
}

# ## install_services
# Registers Open edX components as native OS services.
install_services() {
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  printf '[INFO] Installing Open edX native services...\n'
  mkdir -p "${OPENEDX_INSTALL_DIR}/codebase" "${OPENEDX_INSTALL_DIR}/logs" "${OPENEDX_INSTALL_DIR}/run"
  
  _py="python3"
  if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ]; then
    _py="${OPENEDX_INSTALL_DIR}/.venv/bin/python"
  fi
  if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn" ]; then
    _exec_lms="${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn --bind 0.0.0.0:${LMS_PORT} --workers 4 lms.wsgi:application"
    _exec_cms="${OPENEDX_INSTALL_DIR}/.venv/bin/gunicorn --bind 0.0.0.0:${CMS_PORT} --workers 2 cms.wsgi:application"
  else
    _exec_lms="${_py} manage.py lms --settings=libscript runserver --insecure 0.0.0.0:${LMS_PORT} --noreload"
    _exec_cms="${_py} manage.py cms --settings=libscript runserver --insecure 0.0.0.0:${CMS_PORT} --noreload"
  fi
  _exec_lms_worker="${_py} -m celery -A lms.celery worker --loglevel=INFO -c 2"
  _exec_cms_worker="${_py} -m celery -A cms.celery worker --loglevel=INFO -c 2"
  _exec_beat="${_py} -m celery -A lms.celery beat --loglevel=INFO"
  
  libscript_install_service "openedx-lms" "${_exec_lms}" "${OPENEDX_INSTALL_DIR}/codebase" "Open edX LMS Service" ""
  libscript_install_service "openedx-cms" "${_exec_cms}" "${OPENEDX_INSTALL_DIR}/codebase" "Open edX Studio CMS Service" ""
  libscript_install_service "openedx-lms-worker" "${_exec_lms_worker}" "${OPENEDX_INSTALL_DIR}/codebase" "Open edX LMS Celery Worker" ""
  libscript_install_service "openedx-cms-worker" "${_exec_cms_worker}" "${OPENEDX_INSTALL_DIR}/codebase" "Open edX CMS Celery Worker" ""
  libscript_install_service "openedx-celery-beat" "${_exec_beat}" "${OPENEDX_INSTALL_DIR}/codebase" "Open edX Celery Beat Scheduler" ""

  printf '[PASS] Successfully installed Open edX services.\n'
}

# ## uninstall_services
# Unregisters Open edX components from native OS services.
uninstall_services() {
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  printf '[INFO] Uninstalling Open edX native services...\n'
  libscript_uninstall_service "openedx-lms"
  libscript_uninstall_service "openedx-cms"
  libscript_uninstall_service "openedx-lms-worker"
  libscript_uninstall_service "openedx-cms-worker"
  libscript_uninstall_service "openedx-celery-beat"
  printf '[PASS] Successfully uninstalled Open edX services.\n'
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
  install-service)
    install_services
    ;;
  uninstall-service)
    uninstall_services
    ;;
  lms)
    if is_port_listening "$LMS_PORT"; then
      printf '[INFO] LMS is active at http://localhost:%s\n' "$LMS_PORT"
    else
      start_services
    fi
    ;;
  studio|cms)
    if is_port_listening "$CMS_PORT"; then
      printf '[INFO] Studio CMS is active at http://localhost:%s\n' "$CMS_PORT"
    else
      start_services
    fi
    ;;
  help|-h|--help|/?)
    show_help
    ;;
  *)
    printf '[ERROR] Unknown subcommand: %s\n' "$ACTION" >&2
    show_help
    ;;
esac
exit 0
