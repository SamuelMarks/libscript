#!/bin/sh
# ## Overview
# Scans the host system to discover active database instances (MySQL, Postgres, MongoDB, Redis).
# Supports POSIX services and TCP/UNIX socket probing.
#
# ## Usage
#   ./discover_databases.sh [--json | --eval | --check --engine <type>]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

# ## discover_tcp_port
# Checks if a given TCP port is locally listening.
discover_tcp_port() {
  _port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn | grep -q ":$_port " && return 0
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an | grep -E "LISTEN.*[:.]$_port " >/dev/null 2>&1 && return 0
  fi
  return 1
}

# ## discover_unix_socket
# Checks if a given UNIX socket exists.
discover_unix_socket() {
  _sock="$1"
  if [ -S "$_sock" ]; then return 0; else return 1; fi
}

MODE="eval"
TARGET_ENGINE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json) MODE="json"; shift ;;
    --eval) MODE="eval"; shift ;;
    --check) MODE="check"; shift ;;
    --engine) TARGET_ENGINE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ "$MODE" = "check" ] && [ -n "$TARGET_ENGINE" ]; then
  case "$TARGET_ENGINE" in
    mysql|mariadb) (discover_tcp_port 3306 || discover_unix_socket /tmp/mysql.sock || discover_unix_socket /var/run/mysqld/mysqld.sock) && exit 0 ;;
    postgres) (discover_tcp_port 5432 || discover_unix_socket /var/run/postgresql/.s.PGSQL.5432) && exit 0 ;;
    mongodb) discover_tcp_port 27017 && exit 0 ;;
    redis) (discover_tcp_port 6379 || discover_unix_socket /var/run/redis/redis.sock) && exit 0 ;;
  esac
  exit 1
fi

found_mysql=false
if discover_tcp_port 3306 || discover_unix_socket /tmp/mysql.sock || discover_unix_socket /var/run/mysqld/mysqld.sock; then found_mysql=true; fi
found_postgres=false
if discover_tcp_port 5432 || discover_unix_socket /var/run/postgresql/.s.PGSQL.5432; then found_postgres=true; fi
found_mongodb=false
if discover_tcp_port 27017; then found_mongodb=true; fi
found_redis=false
if discover_tcp_port 6379; then found_redis=true; fi

if [ "$MODE" = "json" ]; then
  printf '[\n'
  first=true
  if $found_mysql; then
    printf '  {"engine": "mysql", "host": "127.0.0.1", "port": 3306, "is_active": true, "source": "tcp_probe"}'
    first=false
  fi
  if $found_postgres; then
    $first || printf ',\n'
    printf '  {"engine": "postgres", "host": "127.0.0.1", "port": 5432, "is_active": true, "source": "tcp_probe"}'
    first=false
  fi
  if $found_mongodb; then
    $first || printf ',\n'
    printf '  {"engine": "mongodb", "host": "127.0.0.1", "port": 27017, "is_active": true, "source": "tcp_probe"}'
    first=false
  fi
  if $found_redis; then
    $first || printf ',\n'
    printf '  {"engine": "redis", "host": "127.0.0.1", "port": 6379, "is_active": true, "source": "tcp_probe"}'
  fi
  printf '\n]\n'
elif [ "$MODE" = "eval" ]; then
  if $found_mysql; then
    printf 'export DETECTED_DB_ENGINE="mysql"\nexport DETECTED_DB_HOST="127.0.0.1"\nexport DETECTED_DB_PORT="3306"\n'
  elif $found_postgres; then
    printf 'export DETECTED_DB_ENGINE="postgres"\nexport DETECTED_DB_HOST="127.0.0.1"\nexport DETECTED_DB_PORT="5432"\n'
  fi
fi
exit 0