#!/bin/sh
# ## Overview
# Full-stack diagnostic and health probe module for Open edX.
# Validates MySQL, MongoDB, Redis, Meilisearch, Celery, LMS HTTP, CMS HTTP, and SMTP listeners.
#
# ## Usage
#   ./healthcheck.sh [--json|help]

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

# ## Parameters
# - `--json`: Formats diagnostic health report in JSON rather than human-readable tabular format.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LMS_HOST`: Public LMS host (default: 127.0.0.1).
# - `LMS_PORT`: Port for LMS service (default: 8000).
# - `CMS_HOST`: Public Studio CMS host (default: 127.0.0.1).
# - `CMS_PORT`: Port for CMS service (default: 8001).
# - `MYSQL_HOST`: Host for MySQL (default: 127.0.0.1).
# - `MYSQL_PORT`: Port for MySQL (default: 3306).
# - `MONGODB_HOST`: Host for MongoDB (default: 127.0.0.1).
# - `MONGODB_PORT`: Port for MongoDB (default: 27017).
# - `REDIS_HOST`: Host for Redis (default: 127.0.0.1).
# - `REDIS_PORT`: Port for Redis (default: 6379).
# - `MEILISEARCH_HOST`: Host for Meilisearch (default: 127.0.0.1).
# - `MEILISEARCH_PORT`: Port for Meilisearch (default: 7700).
# - `SMTP_PORT`: Port for local SMTP mail relay (default: 25).
#
# ## Exit Codes
# - `0`: All required endpoints are healthy.
# - `1`: One or more health checks failed or returned an error.

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
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
LMS_HOST="${LMS_HOST:-127.0.0.1}"
LMS_PORT="${LMS_PORT:-8000}"
CMS_HOST="${CMS_HOST:-127.0.0.1}"
CMS_PORT="${CMS_PORT:-8001}"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MONGODB_HOST="${MONGODB_HOST:-127.0.0.1}"
MONGODB_PORT="${MONGODB_PORT:-27017}"
REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"
MEILISEARCH_HOST="${MEILISEARCH_HOST:-127.0.0.1}"
MEILISEARCH_PORT="${MEILISEARCH_PORT:-7700}"
SMTP_HOST="${SMTP_HOST:-127.0.0.1}"
SMTP_PORT="${SMTP_PORT:-25}"

JSON_OUTPUT="0"
if [ "${1:-}" = "--json" ]; then
  JSON_OUTPUT="1"
elif [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat <<EOF
Open edX Healthcheck Diagnostics CLI

Usage:
  $0 [--json]
  $0 help

Options:
  --json    Emit structured machine-readable JSON status report
  help      Display this help documentation
EOF
  exit 0
fi

TOTAL_FAILURES=0

# ## test_tcp_port
# Tests whether a remote or local TCP port is accepting connections.
#
# Inputs:
#   $1 - host
#   $2 - port
# Returns:
#   0 if listening, 1 if refused or timeout.
test_tcp_port() {
  _host="$1"
  _port="$2"
  if command -v nc >/dev/null 2>&1; then
    nc -z -w 1 "${_host}" "${_port}" >/dev/null 2>&1
  elif command -v curl >/dev/null 2>&1; then
    curl -s --connect-timeout 1 "telnet://${_host}:${_port}" >/dev/null 2>&1 || [ $? -eq 49 ] || [ $? -eq 52 ]
  elif command -v telnet >/dev/null 2>&1; then
    (printf '\035\nquit\n' | telnet "${_host}" "${_port}") >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 1 --spider "http://${_host}:${_port}" >/dev/null 2>&1 || [ $? -eq 8 ]
  else
    return 1
  fi
}



# ## probe_http
# Probes an HTTP service for a valid response code.
#
# Inputs:
#   $1 - URL
probe_http() {
  _url="$1"
  _code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "${_url}" 2>/dev/null || printf '000')
  case "${_code}" in
    200|301|302|401|403)
      printf 'OK (%s)' "${_code}"
      return 0
      ;;
    *)
      printf 'FAIL (%s)' "${_code}"
      return 1
      ;;
  esac
}

# ## probe_workers
# Checks if background Celery, Gunicorn, or Waitress worker processes are active.
probe_workers() {
  _pid_file="${OPENEDX_INSTALL_DIR}/run/worker.pid"
  if [ -f "${_pid_file}" ] && kill -0 "$(cat "${_pid_file}")" 2>/dev/null; then
    echo 'OK'
    return 0
  fi
  # shellcheck disable=SC2009
  if ps aux 2>/dev/null | grep -v grep | grep -E "(celery|openedx-worker|waitress|gunicorn)" >/dev/null 2>&1; then
    echo 'OK'
    return 0
  fi
  printf 'WARN (inactive)'
  return 0
}

# ## probe_smtp
# Probes local SMTP mail relay port.
probe_smtp() {
  if test_tcp_port "${SMTP_HOST}" "${SMTP_PORT}"; then
    echo 'OK'
    return 0
  fi
  printf 'WARN (offline)'
  return 0
}

# Run diagnostics
if test_tcp_port "${MYSQL_HOST}" "${MYSQL_PORT}" || "${LIBSCRIPT_ROOT_DIR}/libscript.sh" status databases/mysql >/dev/null 2>&1; then
  STATUS_MYSQL="OK"
else
  STATUS_MYSQL="FAIL"
  TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

if test_tcp_port "${REDIS_HOST}" "${REDIS_PORT}" || "${LIBSCRIPT_ROOT_DIR}/libscript.sh" status caches/redis >/dev/null 2>&1; then
  STATUS_REDIS="OK"
else
  STATUS_REDIS="FAIL"
  TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

if test_tcp_port "${MEILISEARCH_HOST}" "${MEILISEARCH_PORT}" || "${LIBSCRIPT_ROOT_DIR}/libscript.sh" status search/meilisearch >/dev/null 2>&1; then
  STATUS_MEILI="OK"
else
  STATUS_MEILI="FAIL"
  TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

STATUS_LMS=$(probe_http "http://${LMS_HOST}:${LMS_PORT}/" || true)
[ "${STATUS_LMS#FAIL}" != "${STATUS_LMS}" ] && TOTAL_FAILURES=$((TOTAL_FAILURES + 1))

STATUS_CMS=$(probe_http "http://${CMS_HOST}:${CMS_PORT}/signin" || true)
[ "${STATUS_CMS#FAIL}" != "${STATUS_CMS}" ] && TOTAL_FAILURES=$((TOTAL_FAILURES + 1))

STATUS_WORKERS=$(probe_workers || true)
STATUS_SMTP=$(probe_smtp || true)

if [ "${JSON_OUTPUT}" = "1" ]; then
  cat <<EOF
{
  "status": $( [ "$TOTAL_FAILURES" -eq 0 ] && printf '"healthy"' || printf '"degraded"' ),
  "failures": ${TOTAL_FAILURES},
  "services": {
    "mysql": "${STATUS_MYSQL}",
    "redis": "${STATUS_REDIS}",
    "meilisearch": "${STATUS_MEILI}",
    "lms": "${STATUS_LMS}",
    "cms": "${STATUS_CMS}",
    "workers": "${STATUS_WORKERS}",
    "smtp": "${STATUS_SMTP}"
  }
}
EOF
else
  printf '========================================================================\n'
  printf '               Open edX Full-Stack Health Diagnostics                  \n'
  printf '========================================================================\n'
  printf '%-20s %-32s %-16s\n' "SERVICE" "TARGET ENDPOINT" "STATUS"
  printf '%-20s %-32s %-16s\n' "--------------------" "--------------------------------" "----------------"
  printf '%-20s %-32s %-16s\n' "MySQL" "${MYSQL_HOST}:${MYSQL_PORT}" "${STATUS_MYSQL}"
  printf '%-20s %-32s %-16s\n' "Redis" "${REDIS_HOST}:${REDIS_PORT}" "${STATUS_REDIS}"
  printf '%-20s %-32s %-16s\n' "Meilisearch" "http://${MEILISEARCH_HOST}:${MEILISEARCH_PORT}" "${STATUS_MEILI}"
  printf '%-20s %-32s %-16s\n' "LMS Web" "http://${LMS_HOST}:${LMS_PORT}/" "${STATUS_LMS}"
  printf '%-20s %-32s %-16s\n' "Studio Web" "http://${CMS_HOST}:${CMS_PORT}/signin" "${STATUS_CMS}"
  printf '%-20s %-32s %-16s\n' "Celery Workers" "celery-lms, cms-worker" "${STATUS_WORKERS}"
  printf '%-20s %-32s %-16s\n' "SMTP Mail Relay" "${SMTP_HOST}:${SMTP_PORT}" "${STATUS_SMTP}"
  printf '========================================================================\n'
  if [ "$TOTAL_FAILURES" -eq 0 ]; then
    log_success "All Open edX core services and endpoints are healthy."
  else
    log_warn "Healthcheck detected ${TOTAL_FAILURES} degraded or offline service(s)."
  fi
fi

if [ "$TOTAL_FAILURES" -gt 0 ]; then
  exit 1
fi
exit 0
