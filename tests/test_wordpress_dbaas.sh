#!/bin/sh
# ## Overview
# Verification test for hosted DBaaS connectivity and SSL configuration in WordPress 7.1.2.
# Tests URL parsing, parameter extraction, and wp-config.php generation for remote DBaaS.
#
# ## Usage
#   ./tests/test_wordpress_dbaas.sh

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

printf '==> Testing DBaaS Connection URL Parser...
'
PARSE_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_dbaas_url.sh"

DBAAS_TEST_URL="mysql://wp_cloud_user:SecretP%40ss2026%21@db-cluster.us-east-1.rds.amazonaws.com:3307/wordpress_prod?ssl-ca=/etc/ssl/rds-ca.pem&ssl-mode=REQUIRED"

_parsed_dbaas=$("$PARSE_SH" "$DBAAS_TEST_URL" --eval)
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
    DB_USE_SSL) DB_USE_SSL="$_v" ;;
    DB_SSL_CA) DB_SSL_CA="$_v" ;;
    DB_SSL_MODE) DB_SSL_MODE="$_v" ;;
  esac
done << EOF
$_parsed_dbaas
EOF

if [ "$DB_USER" != "wp_cloud_user" ]; then
  printf '[ERROR] DB_USER parse failed. Expected wp_cloud_user, got: %s
' "$DB_USER" >&2
  exit 1
fi

if [ "$DB_PASSWORD" != "SecretP@ss2026!" ]; then
  printf '[ERROR] DB_PASSWORD percent decode failed. Expected SecretP@ss2026!, got: %s
' "$DB_PASSWORD" >&2
  exit 1
fi

if [ "$DB_HOST" != "db-cluster.us-east-1.rds.amazonaws.com" ]; then
  printf '[ERROR] DB_HOST parse failed: %s
' "$DB_HOST" >&2
  exit 1
fi

if [ "$DB_PORT" != "3307" ]; then
  printf '[ERROR] DB_PORT parse failed: %s
' "$DB_PORT" >&2
  exit 1
fi

if [ "$DB_NAME" != "wordpress_prod" ]; then
  printf '[ERROR] DB_NAME parse failed: %s
' "$DB_NAME" >&2
  exit 1
fi

if [ "$DB_USE_SSL" -ne 1 ] || [ "$DB_SSL_CA" != "/etc/ssl/rds-ca.pem" ]; then
  printf '[ERROR] SSL parameters parse failed: USE_SSL=%s, CA=%s
' "$DB_USE_SSL" "$DB_SSL_CA" >&2
  exit 1
fi

printf '[OK] DBaaS URL parser validated successfully!
'

# Test wp-config.php synthesis with DBaaS URL
TMP_WWW=$(mktemp -d)
printf '[INFO] Testing wp-config synthesis with DBaaS URL in %s...
' "$TMP_WWW"

"${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh" --wwwroot "$TMP_WWW" --mysql-url "$DBAAS_TEST_URL" --skip-deps --server-name "wordpress.local"

if ! grep -q "define( *'DB_HOST', *'db-cluster.us-east-1.rds.amazonaws.com:3307'" "${TMP_WWW}/wp-config.php"; then
  printf '[ERROR] DB_HOST with custom port not present in wp-config.php!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

if ! grep -q "define( *'MYSQL_CLIENT_FLAGS', *MYSQLI_CLIENT_SSL" "${TMP_WWW}/wp-config.php"; then
  printf '[ERROR] MYSQLI_CLIENT_SSL flag not present in wp-config.php!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

if ! grep -q "define( *'MYSQL_SSL_CA', *'/etc/ssl/rds-ca.pem'" "${TMP_WWW}/wp-config.php"; then
  printf '[ERROR] MYSQL_SSL_CA not present in wp-config.php!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

rm -rf "$TMP_WWW"
printf '==> All hosted DBaaS integration tests passed successfully!
'
exit 0
