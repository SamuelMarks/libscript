#!/bin/sh
# ## Overview
# Universal database connection URI parser supporting MySQL, MariaDB, PostgreSQL,
# MongoDB, Redis, and SQLite. Decodes percent-encoded credentials and extracts
# query parameters (TLS/SSL certificates, timeouts, SNI).
#
# ## Usage
#   ./_lib/databases/parse_connection_uri.sh <URI> [--eval|--json|--export]
#
# ## Exit Codes
#   0 - URI successfully parsed
#   1 - Invalid URI format or missing required parameter

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

RAW_URI="${1:-}"
MODE="${2:---eval}"

if [ -z "$RAW_URI" ]; then
  printf '[ERROR] No URI provided to parse_connection_uri.sh
' >&2
  exit 1
fi

# ## urldecode
# Decodes percent-encoded characters (%20, %40, etc.) in a URI component.
urldecode() {
  _val="$1"
  printf '%s' "$_val" | awk '
  BEGIN {
    for (i = 0; i <= 255; i++) hex[sprintf("%02X", i)] = sprintf("%c", i);
    for (i = 0; i <= 255; i++) hex[sprintf("%02x", i)] = sprintf("%c", i);
  }
  {
    gsub(/\+/, " ");
    s = "";
    len = length($0);
    for (i = 1; i <= len; i++) {
      c = substr($0, i, 1);
      if (c == "%" && i + 2 <= len) {
        h = substr($0, i + 1, 2);
        if (h in hex) {
          s = s hex[h];
          i += 2;
          continue;
        }
      }
      s = s c;
    }
    printf "%s", s;
  }'
}

# 1. Identify and strip scheme
scheme=""
body="$RAW_URI"
case "$body" in
  mysql://*)
    scheme="mysql"
    body="${body#mysql://}"
    ;;
  mariadb://*)
    scheme="mariadb"
    body="${body#mariadb://}"
    ;;
  postgres://*)
    scheme="postgres"
    body="${body#postgres://}"
    ;;
  postgresql://*)
    scheme="postgres"
    body="${body#postgresql://}"
    ;;
  mongodb://*)
    scheme="mongodb"
    body="${body#mongodb://}"
    ;;
  redis://*)
    scheme="redis"
    body="${body#redis://}"
    ;;
  sqlite://*)
    scheme="sqlite"
    body="${body#sqlite://}"
    ;;
  *)
    scheme="mysql"
    ;;
esac

# Handle SQLite specifically (sqlite:///path/to/file.db or sqlite://C:/path)
if [ "$scheme" = "sqlite" ]; then
  sqlite_path="$body"
  query_str=""
  case "$sqlite_path" in
    *\?*)
      query_str="${sqlite_path#*\?}"
      sqlite_path="${sqlite_path%%\?*}"
      ;;
  esac
  case "$MODE" in
    --export)
      export DB_ENGINE="sqlite"
      export DB_PATH="$sqlite_path"
      ;;
    --json)
      printf '{"engine":"sqlite","path":"%s"}
' "$sqlite_path"
      ;;
    --eval|*)
      printf 'DB_ENGINE="sqlite"
'
      printf 'DB_PATH="%s"
' "$sqlite_path"
      ;;
  esac
  exit 0
fi

# 2. Extract query string
query_str=""
case "$body" in
  *\?*)
    query_str="${body#*\?}"
    body="${body%%\?*}"
    ;;
esac

# 3. Extract path (database or keyspace name or redis db index)
db_name=""
case "$body" in
  */*)
    db_name="${body#*/}"
    body="${body%%/*}"
    ;;
esac

# 4. Extract auth part vs host part
db_user=""
db_pass=""
host_part="$body"

case "$body" in
  *@*)
    auth_part="${body%%@*}"
    host_part="${body#*@}"
    case "$auth_part" in
      *:*)
        db_user="$(urldecode "${auth_part%%:*}")"
        db_pass="$(urldecode "${auth_part#*:}")"
        ;;
      *)
        db_user="$(urldecode "$auth_part")"
        ;;
    esac
    ;;
esac

# 5. Extract host vs port
default_port="3306"
case "$scheme" in
  mysql|mariadb) default_port="3306" ;;
  postgres) default_port="5432" ;;
  mongodb) default_port="27017" ;;
  redis) default_port="6379" ;;
esac

db_host="127.0.0.1"
db_port="$default_port"

case "$host_part" in
  *:*)
    db_host="${host_part%%:*}"
    db_port="${host_part#*:}"
    ;;
  *)
    if [ -n "$host_part" ]; then
      db_host="$host_part"
    fi
    ;;
esac

# 6. Parse query string parameters (ssl-ca, ssl-cert, ssl-key, ssl-mode, timeout, charset)
db_ssl_ca=""
db_ssl_cert=""
db_ssl_key=""
db_ssl_mode=""
db_use_ssl=0
db_timeout=""
db_charset=""

if [ -n "$query_str" ]; then
  db_use_ssl=1
  old_ifs="$IFS"
  IFS='&'
  set -- $query_str
  IFS="$old_ifs"
  for param in "$@"; do
    case "$param" in
      ssl-ca=*|ssl_ca=*)
        db_ssl_ca="$(urldecode "${param#*=}")"
        ;;
      ssl-cert=*|ssl_cert=*)
        db_ssl_cert="$(urldecode "${param#*=}")"
        ;;
      ssl-key=*|ssl_key=*)
        db_ssl_key="$(urldecode "${param#*=}")"
        ;;
      ssl-mode=*|ssl_mode=*)
        db_ssl_mode="$(urldecode "${param#*=}")"
        ;;
      ssl=true|ssl=1)
        db_use_ssl=1
        ;;
      timeout=*)
        db_timeout="$(urldecode "${param#*=}")"
        ;;
      charset=*)
        db_charset="$(urldecode "${param#*=}")"
        ;;
    esac
  done
fi

case "$MODE" in
  --export)
    export DB_ENGINE="$scheme"
    export DB_HOST="$db_host"
    export DB_PORT="$db_port"
    export DB_NAME="$db_name"
    export DB_USER="$db_user"
    export DB_PASSWORD="$db_pass"
    export DB_USE_SSL="$db_use_ssl"
    export DB_SSL_CA="$db_ssl_ca"
    export DB_SSL_CERT="$db_ssl_cert"
    export DB_SSL_KEY="$db_ssl_key"
    export DB_SSL_MODE="$db_ssl_mode"
    export DB_TIMEOUT="$db_timeout"
    export DB_CHARSET="$db_charset"
    ;;
  --json)
    printf '{
'
    printf '  "engine": "%s",
' "$scheme"
    printf '  "host": "%s",
' "$db_host"
    printf '  "port": %s,
' "$db_port"
    printf '  "name": "%s",
' "$db_name"
    printf '  "user": "%s",
' "$db_user"
    printf '  "password": "%s",
' "$db_pass"
    printf '  "use_ssl": %s,
' "$([ "$db_use_ssl" -eq 1 ] && printf 'true' || printf 'false')"
    printf '  "ssl_ca": "%s",
' "$db_ssl_ca"
    printf '  "ssl_cert": "%s",
' "$db_ssl_cert"
    printf '  "ssl_key": "%s",
' "$db_ssl_key"
    printf '  "ssl_mode": "%s",
' "$db_ssl_mode"
    printf '  "timeout": "%s",
' "$db_timeout"
    printf '  "charset": "%s"
' "$db_charset"
    printf '}
'
    ;;
  --eval|*)
    printf 'DB_ENGINE="%s"
' "$scheme"
    printf 'DB_HOST="%s"
' "$db_host"
    printf 'DB_PORT=%s
' "$db_port"
    printf 'DB_NAME="%s"
' "$db_name"
    printf 'DB_USER="%s"
' "$db_user"
    printf 'DB_PASSWORD="%s"
' "$db_pass"
    printf 'DB_USE_SSL=%d
' "$db_use_ssl"
    printf 'DB_SSL_CA="%s"
' "$db_ssl_ca"
    printf 'DB_SSL_CERT="%s"
' "$db_ssl_cert"
    printf 'DB_SSL_KEY="%s"
' "$db_ssl_key"
    printf 'DB_SSL_MODE="%s"
' "$db_ssl_mode"
    printf 'DB_TIMEOUT="%s"
' "$db_timeout"
    printf 'DB_CHARSET="%s"
' "$db_charset"
    ;;
esac
