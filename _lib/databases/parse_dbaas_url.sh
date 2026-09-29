#!/bin/sh
# ## Overview
# Parses a MySQL/MariaDB DBaaS connection URI string into distinct connection parameters.
# Supports authentication, custom ports, database schema names, and TLS/SSL query parameters.
#
# ## Usage
#   ./_lib/databases/parse_dbaas_url.sh <connection_url> [--eval|--json|--export]
#
# ## Parameters
#   $1 - Database connection URI (e.g. mysql://user:pass@host:3306/dbname?ssl-ca=ca.pem)
#   $2 - Output mode (--eval, --json, --export; default: --eval)

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

RAW_URL="${1:-}"
MODE="${2:---eval}"

if [ -z "$RAW_URL" ]; then
  printf '[ERROR] No connection URL provided to parse_dbaas_url.sh
' >&2
  exit 1
fi

# ## urldecode
# Decodes percent-encoded characters in a URI component.
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

# 1. Strip protocol prefix (e.g. mysql:// or mariadb://)
url_body="$RAW_URL"
case "$url_body" in
  mysql://*)
    url_body="${url_body#mysql://}"
    ;;
  mariadb://*)
    url_body="${url_body#mariadb://}"
    ;;
  *)
    # Default to raw body
    ;;
esac

# 2. Extract query string if present
query_str=""
case "$url_body" in
  *\?*)
    query_str="${url_body#*\?}"
    url_body="${url_body%%\?*}"
    ;;
esac

# 3. Extract database path
db_name="wordpress"
case "$url_body" in
  */*)
    db_name="${url_body#*/}"
    url_body="${url_body%%/*}"
    ;;
esac

# 4. Extract user:password vs host:port
db_user="root"
db_pass=""
case "$url_body" in
  *@*)
    auth_part="${url_body%%@*}"
    host_part="${url_body#*@}"
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
  *)
    host_part="$url_body"
    ;;
esac

# 5. Extract host vs port
db_host="127.0.0.1"
db_port="3306"
case "$host_part" in
  *:*)
    db_host="${host_part%%:*}"
    db_port="${host_part#*:}"
    ;;
  *)
    db_host="$host_part"
    ;;
esac

# 6. Parse query string parameters (ssl-ca, ssl-mode, ssl-cert, ssl-key, charset)
db_ssl_ca=""
db_ssl_cert=""
db_ssl_key=""
db_ssl_mode=""
db_use_ssl=0

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
    esac
  done
fi

case "$MODE" in
  --export)
    export DB_HOST="$db_host"
    export DB_PORT="$db_port"
    export DB_NAME="$db_name"
    export DB_USER="$db_user"
    export DB_PASSWORD="$db_pass"
    export DB_SSL_CA="$db_ssl_ca"
    export DB_SSL_CERT="$db_ssl_cert"
    export DB_SSL_KEY="$db_ssl_key"
    export DB_SSL_MODE="$db_ssl_mode"
    export DB_USE_SSL="$db_use_ssl"
    ;;
  --json)
    printf '{"host":"%s","port":%s,"name":"%s","user":"%s","password":"%s","use_ssl":%s,"ssl_ca":"%s","ssl_cert":"%s","ssl_key":"%s","ssl_mode":"%s"}\n' \
      "$db_host" "$db_port" "$db_name" "$db_user" "$db_pass" \
      "$([ "$db_use_ssl" -eq 1 ] && printf 'true' || printf 'false')" \
      "$db_ssl_ca" "$db_ssl_cert" "$db_ssl_key" "$db_ssl_mode"
    ;;
  --eval|*)
    printf 'DB_HOST="%s"
' "$db_host"
    printf 'DB_PORT="%s"
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
    ;;
esac
