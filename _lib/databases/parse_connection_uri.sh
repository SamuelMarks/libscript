#!/bin/sh
# ## Overview
# Universal connection URI parser for database connection strings.
# Supports mysql://, postgres://, mongodb://, redis://, sqlite://.
#
# ## Usage
#   ./parse_connection_uri.sh <URI> [--eval | --json | --export]

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

uri="${1:-}"
mode="${2:---eval}"

if [ -z "$uri" ]; then
  printf 'Error: URI required\n' >&2
  exit 1
fi

# Extract protocol (engine)
engine="${uri%%://*}"
rest="${uri#*://}"

# Extract credentials if present
case "$rest" in
  *@*)
    creds="${rest%%@*}"
    hostport_path="${rest#*@}"
    user="${creds%%:*}"
    pass="${creds#*:}"
    [ "$user" = "$pass" ] && pass=""
    ;;
  *)
    user=""
    pass=""
    hostport_path="$rest"
    ;;
esac

# Extract path and query params
path_params="${hostport_path#*/}"
hostport="${hostport_path%%/*}"
if [ "$hostport_path" = "$hostport" ]; then
    path_params=""
fi

# Extract host and port
host="${hostport%%:*}"
port="${hostport#*:}"
[ "$host" = "$port" ] && port=""

# Extract dbname and query
dbname="${path_params%%[?]*}"
query="${path_params#*[?]}"
[ "$dbname" = "$query" ] && query=""

# Minimal awk percent decoding
if [ -n "$pass" ]; then
  pass=$(printf '%s' "$pass" | awk '{
    gsub(/%20/, " "); gsub(/%21/, "!"); gsub(/%40/, "@"); gsub(/%23/, "#"); 
    gsub(/%24/, "$"); gsub(/%25/, "%"); gsub(/%5E/, "^"); 
    gsub(/%26/, "\\&"); gsub(/%2A/, "*"); gsub(/%3D/, "="); print
  }')
fi
if [ -n "$user" ]; then
  user=$(printf '%s' "$user" | awk '{
    gsub(/%40/, "@"); print
  }')
fi

db_use_ssl="0"
db_ssl_ca=""
db_ssl_cert=""
db_ssl_key=""
db_ssl_mode=""
db_timeout=""
db_charset=""

if [ -n "$query" ]; then
  # Parse query string
  # Split query on & and iterate
  OIFS="$IFS"
  IFS="&"
  for param in $query; do
    IFS="$OIFS"
    k="${param%%=*}"
    v="${param#*=}"
    case "$k" in
      ssl-ca|ssl_ca) db_ssl_ca="$v"; db_use_ssl="1" ;;
      ssl-cert|ssl_cert) db_ssl_cert="$v"; db_use_ssl="1" ;;
      ssl-key|ssl_key) db_ssl_key="$v"; db_use_ssl="1" ;;
      ssl-mode|sslmode) db_ssl_mode="$v"; db_use_ssl="1" ;;
      timeout|connect_timeout) db_timeout="$v" ;;
      charset) db_charset="$v" ;;
      ssl) if [ "$v" = "true" ] || [ "$v" = "1" ]; then db_use_ssl="1"; fi ;;
    esac
  done
  IFS="$OIFS"
fi

case "$mode" in
  --eval)
    printf 'DB_ENGINE="%s"\nDB_HOST="%s"\nDB_PORT="%s"\nDB_USER="%s"\nDB_PASS="%s"\nDB_NAME="%s"\nDB_QUERY="%s"\nDB_USE_SSL="%s"\nDB_SSL_CA="%s"\nDB_SSL_CERT="%s"\nDB_SSL_KEY="%s"\nDB_SSL_MODE="%s"\nDB_TIMEOUT="%s"\nDB_CHARSET="%s"\n' \
      "$engine" "$host" "$port" "$user" "$pass" "$dbname" "$query" "$db_use_ssl" "$db_ssl_ca" "$db_ssl_cert" "$db_ssl_key" "$db_ssl_mode" "$db_timeout" "$db_charset"
    ;;
  --export)
    printf 'export DB_ENGINE="%s"\nexport DB_HOST="%s"\nexport DB_PORT="%s"\nexport DB_USER="%s"\nexport DB_PASS="%s"\nexport DB_NAME="%s"\nexport DB_QUERY="%s"\nexport DB_USE_SSL="%s"\nexport DB_SSL_CA="%s"\nexport DB_SSL_CERT="%s"\nexport DB_SSL_KEY="%s"\nexport DB_SSL_MODE="%s"\nexport DB_TIMEOUT="%s"\nexport DB_CHARSET="%s"\n' \
      "$engine" "$host" "$port" "$user" "$pass" "$dbname" "$query" "$db_use_ssl" "$db_ssl_ca" "$db_ssl_cert" "$db_ssl_key" "$db_ssl_mode" "$db_timeout" "$db_charset"
    ;;
  --json)
    printf '{"engine":"%s","host":"%s","port":"%s","user":"%s","pass":"%s","dbname":"%s","query":"%s","use_ssl":%s,"ssl_ca":"%s","ssl_cert":"%s","ssl_key":"%s","ssl_mode":"%s","timeout":"%s","charset":"%s"}\n' \
      "$engine" "$host" "$port" "$user" "$pass" "$dbname" "$query" "${db_use_ssl:-0}" "$db_ssl_ca" "$db_ssl_cert" "$db_ssl_key" "$db_ssl_mode" "$db_timeout" "$db_charset"
    ;;
esac
exit 0