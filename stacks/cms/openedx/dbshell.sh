#!/bin/sh
# ## Overview
# Database console and query execution wrapper for Open edX.
# Provides unified CLI access to MySQL, MongoDB, and Redis datastores.
#
# ## Usage
#   ./dbshell.sh mysql [optional_mysql_args...]
#   ./dbshell.sh mongo [optional_mongo_args...]
#   ./dbshell.sh redis [optional_redis_args...]
#   ./dbshell.sh query <sql_statement>
#   ./dbshell.sh help
#
# ## Parameters
# - `mysql`: Connects to MySQL using configured stack credentials.
# - `mongo`: Connects to MongoDB via mongosh or mongo client.
# - `redis`: Connects to Redis via redis-cli.
# - `query`: Runs a non-interactive SQL query against the primary MySQL database.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `MYSQL_DATABASE`: MySQL database name (default: openedx).
# - `MYSQL_USER`: MySQL user (default: openedx).
# - `MYSQL_PASSWORD`: MySQL password.
# - `MYSQL_HOST`: MySQL host (default: 127.0.0.1).
# - `MYSQL_PORT`: MySQL port (default: 3306).
# - `MONGODB_HOST`: MongoDB host (default: 127.0.0.1).
# - `MONGODB_PORT`: MongoDB port (default: 27017).
# - `MONGODB_DATABASE`: MongoDB database name (default: openedx).
# - `REDIS_HOST`: Redis host (default: 127.0.0.1).
# - `REDIS_PORT`: Redis port (default: 6379).
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Client invocation failure or missing database client binary.

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
export DIR="${SCRIPT_DIR}"

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
CONFIG_JSON="${OPENEDX_INSTALL_DIR}/config/lms.env.json"

# Read database parameters with configuration file fallbacks
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-openedx}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
MYSQL_DATABASE="${MYSQL_DATABASE:-openedx}"

MONGODB_HOST="${MONGODB_HOST:-127.0.0.1}"
MONGODB_PORT="${MONGODB_PORT:-27017}"
MONGODB_DATABASE="${MONGODB_DATABASE:-openedx}"

REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

# If lms.env.json exists, parse configuration overrides using python
if [ -f "${CONFIG_JSON}" ] && command -v python3 >/dev/null 2>&1; then
  _cfg_tmp=$(mktemp)
  python3 - "${CONFIG_JSON}" > "$_cfg_tmp" 2>/dev/null << 'EOF' || true
import json, sys
try:
    with open(sys.argv[1]) as f:
        cfg = json.load(f)
    db = cfg.get("DATABASES", {}).get("default", {})
    if db.get("HOST"): print(f'MYSQL_HOST={db["HOST"]}')
    if db.get("PORT"): print(f'MYSQL_PORT={db["PORT"]}')
    if db.get("USER"): print(f'MYSQL_USER={db["USER"]}')
    if db.get("PASSWORD"): print(f'MYSQL_PASSWORD={db["PASSWORD"]}')
    if db.get("NAME"): print(f'MYSQL_DATABASE={db["NAME"]}')
except Exception:
    pass
EOF
  while IFS='=' read -r key val; do
    case "$key" in
      MYSQL_HOST) [ -n "$val" ] && MYSQL_HOST="$val" ;;
      MYSQL_PORT) [ -n "$val" ] && MYSQL_PORT="$val" ;;
      MYSQL_USER) [ -n "$val" ] && MYSQL_USER="$val" ;;
      MYSQL_PASSWORD) [ -n "$val" ] && MYSQL_PASSWORD="$val" ;;
      MYSQL_DATABASE) [ -n "$val" ] && MYSQL_DATABASE="$val" ;;
    esac
  done < "$_cfg_tmp"
  rm -f "$_cfg_tmp"
fi

# ## run_mysql
# Connects to MySQL interactive console or passes arguments.
#
# Inputs:
#   $@ - optional mysql arguments
run_mysql() {
  log_info "Connecting to MySQL on ${MYSQL_HOST}:${MYSQL_PORT} (db: ${MYSQL_DATABASE})..."
  if command -v mysql >/dev/null 2>&1; then
    if [ -n "${MYSQL_PASSWORD}" ]; then
      export MYSQL_PWD="${MYSQL_PASSWORD}"
    fi
    exec mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" "${MYSQL_DATABASE}" "$@"
  elif command -v mariadb >/dev/null 2>&1; then
    if [ -n "${MYSQL_PASSWORD}" ]; then
      export MYSQL_PWD="${MYSQL_PASSWORD}"
    fi
    exec mariadb -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" "${MYSQL_DATABASE}" "$@"
  else
    log_err "Neither 'mysql' nor 'mariadb' client binary found in PATH."
    return 1
  fi
}

# ## run_mongo
# Connects to MongoDB interactive console or passes arguments.
#
# Inputs:
#   $@ - optional mongo arguments
run_mongo() {
  _uri="mongodb://${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DATABASE}"
  log_info "Connecting to MongoDB at ${_uri}..."
  if command -v mongosh >/dev/null 2>&1; then
    exec mongosh "${_uri}" "$@"
  elif command -v mongo >/dev/null 2>&1; then
    exec mongo "${_uri}" "$@"
  else
    log_err "Neither 'mongosh' nor 'mongo' client binary found in PATH."
    return 1
  fi
}

# ## run_redis
# Connects to Redis interactive console or passes arguments.
#
# Inputs:
#   $@ - optional redis-cli arguments
run_redis() {
  log_info "Connecting to Redis on ${REDIS_HOST}:${REDIS_PORT}..."
  if command -v redis-cli >/dev/null 2>&1; then
    exec redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" "$@"
  elif command -v valkey-cli >/dev/null 2>&1; then
    exec valkey-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" "$@"
  else
    log_err "Neither 'redis-cli' nor 'valkey-cli' client binary found in PATH."
    return 1
  fi
}

# ## run_query
# Executes a non-interactive SQL query against the MySQL database.
#
# Inputs:
#   $1 - SQL statement
run_query() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 query <sql_statement>"
    return 1
  fi
  _sql="$1"
  log_info "Executing query: ${_sql}"
  if command -v mysql >/dev/null 2>&1; then
    if [ -n "${MYSQL_PASSWORD}" ]; then
      export MYSQL_PWD="${MYSQL_PASSWORD}"
    fi
    mysql -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -e "${_sql}" "${MYSQL_DATABASE}"
  elif command -v mariadb >/dev/null 2>&1; then
    if [ -n "${MYSQL_PASSWORD}" ]; then
      export MYSQL_PWD="${MYSQL_PASSWORD}"
    fi
    mariadb -h "${MYSQL_HOST}" -P "${MYSQL_PORT}" -u "${MYSQL_USER}" -e "${_sql}" "${MYSQL_DATABASE}"
  else
    log_err "No MySQL client binary available to execute query."
    return 1
  fi
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Database Console Wrapper

Usage:
  $0 mysql [optional_args...]
  $0 mongo [optional_args...]
  $0 redis [optional_args...]
  $0 query <sql_statement>
  $0 help

Commands:
  mysql     Open MySQL interactive console
  mongo     Open MongoDB interactive console (mongosh / mongo)
  redis     Open Redis interactive CLI (redis-cli / valkey-cli)
  query     Execute a single SQL statement non-interactively
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  mysql)
    run_mysql "$@"
    ;;
  mongo|mongodb|mongosh)
    run_mongo "$@"
    ;;
  redis|redis-cli)
    run_redis "$@"
    ;;
  query|sql)
    run_query "$@"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown database command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
