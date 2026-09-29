#!/bin/sh
# ## Overview
# Verification test suite for universal database connection URI parser.
#
# ## Usage
#   ./tests/test_connection_uri_parser.sh

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

printf '==> Running Universal Connection URI Parser Verification Tests...\n'
PARSE_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh"

# ## parse_and_load
# Parses URI into environment variables safely without dynamic eval.
parse_and_load() {
  _uri_raw="$1"
  _uri_out=$("$PARSE_SH" "$_uri_raw" --eval)
  while IFS='=' read -r _k _v; do
    _v="${_v%\"}"
    _v="${_v#\"}"
    case "$_k" in
      DB_ENGINE) DB_ENGINE="$_v" ;;
      DB_HOST) DB_HOST="$_v" ;;
      DB_PORT) DB_PORT="$_v" ;;
      DB_NAME) DB_NAME="$_v" ;;
      DB_USER) DB_USER="$_v" ;;
      DB_PASSWORD) DB_PASSWORD="$_v" ;;
      DB_PATH) DB_PATH="$_v" ;;
      DB_USE_SSL) DB_USE_SSL="$_v" ;;
      DB_SSL_CA) DB_SSL_CA="$_v" ;;
      DB_SSL_CERT) DB_SSL_CERT="$_v" ;;
      DB_SSL_KEY) DB_SSL_KEY="$_v" ;;
      DB_SSL_MODE) DB_SSL_MODE="$_v" ;;
      DB_TIMEOUT) DB_TIMEOUT="$_v" ;;
      DB_CHARSET) DB_CHARSET="$_v" ;;
    esac
  done << EOF
$_uri_out
EOF
}

# 1. Test MySQL URI with percent-encoded password and SSL params
printf '[TEST 1] Testing MySQL URI parsing...\n'
parse_and_load "mysql://usr_test:p%40ss%23word@db.example.org:3308/sample_db?ssl-ca=/etc/ssl/ca.pem&timeout=15"
[ "$DB_ENGINE" = "mysql" ] || exit 1
[ "$DB_HOST" = "db.example.org" ] || exit 1
[ "$DB_PORT" = "3308" ] || exit 1
[ "$DB_NAME" = "sample_db" ] || exit 1
[ "$DB_USER" = "usr_test" ] || exit 1
[ "$DB_PASSWORD" = 'p@ss#word' ] || exit 1
[ "$DB_USE_SSL" -eq 1 ] || exit 1
[ "$DB_SSL_CA" = "/etc/ssl/ca.pem" ] || exit 1
[ "$DB_TIMEOUT" = "15" ] || exit 1

# 2. Test PostgreSQL URI
printf '[TEST 2] Testing PostgreSQL URI parsing...\n'
parse_and_load "postgres://pg_admin:secure%20token@127.0.0.1:5432/enterprise_db"
[ "$DB_ENGINE" = "postgres" ] || exit 1
[ "$DB_NAME" = "enterprise_db" ] || exit 1
[ "$DB_PASSWORD" = "secure token" ] || exit 1

# 3. Test SQLite URI
printf '[TEST 3] Testing SQLite URI parsing...\n'
parse_and_load "sqlite:///var/lib/app/data.db"
[ "$DB_ENGINE" = "sqlite" ] || exit 1
[ "$DB_PATH" = "/var/lib/app/data.db" ] || exit 1

printf '[SUCCESS] All Connection URI Parser Tests Passed!
'
