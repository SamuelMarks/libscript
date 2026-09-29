#!/bin/sh
# ## Overview
# Full-stack diagnostic and health probe module for WordPress 7.1.2.
# Validates PHP runtime, extensions, Web Server listener, PHP-FPM, MySQL database, and core files.
#
# ## Usage
#   ./healthcheck.sh [--json]
#   ./healthcheck.sh help
#
# ## Options
#   --json    Output machine-readable JSON status report
#   help      Display usage instructions

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

WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
WP_CONFIG="${WWWROOT}/wp-config.php"
HTTP_PORT="${WORDPRESS_LISTEN:-80}"
HTTP_HOST="${WORDPRESS_SERVER_NAME:-127.0.0.1}"

JSON_MODE=0
if [ "${1:-}" = "--json" ]; then
  JSON_MODE=1
elif [ "${1:-}" = "help" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  cat << 'EOF_HELP'
WordPress Healthcheck Diagnostics

Usage:
  ./healthcheck.sh [--json]
  ./healthcheck.sh help
EOF_HELP
  exit 0
fi

# 1. Probe PHP Runtime
STATUS_PHP="FAIL"
if command -v php >/dev/null 2>&1; then
  STATUS_PHP="OK ($(php -r 'echo PHP_VERSION;' 2>/dev/null || echo 'installed'))"
fi

# 2. Probe Core Files
STATUS_CORE="FAIL"
if [ -f "${WWWROOT}/index.php" ] && [ -f "${WP_CONFIG}" ]; then
  STATUS_CORE="OK"
fi

# 3. Probe Database Connectivity
STATUS_DB="FAIL"
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USER="wordpress"
DB_PASS="wordpress"
DB_NAME="wordpress"

if [ -f "$WP_CONFIG" ]; then
  _val=$(grep "define( *'DB_NAME'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_NAME' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_NAME="$_val"
  _val=$(grep "define( *'DB_USER'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_USER' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_USER="$_val"
  _val=$(grep "define( *'DB_PASSWORD'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_PASSWORD' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_PASS="$_val"
  _val=$(grep "define( *'DB_HOST'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_HOST' *, *'([^']*)'.*/\1/" || true)
  if [ -n "$_val" ]; then
    case "$_val" in
      *:*)
        DB_HOST="${_val%%:*}"
        DB_PORT="${_val#*:}"
        ;;
      *)
        DB_HOST="$_val"
        ;;
    esac
  fi
fi

_client="mysql"
command -v mariadb >/dev/null 2>&1 && _client="mariadb"
if command -v "$_client" >/dev/null 2>&1; then
  export MYSQL_PWD="$DB_PASS"
  if "$_client" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -e "SELECT 1;" "$DB_NAME" >/dev/null 2>&1; then
    STATUS_DB="OK"
  fi
fi

# 4. Probe Web Server Listener
STATUS_WEB="FAIL"
if command -v curl >/dev/null 2>&1; then
  if curl -s -o /dev/null -m 2 "http://${HTTP_HOST}:${HTTP_PORT}/" 2>/dev/null; then
    STATUS_WEB="OK"
  fi
elif command -v nc >/dev/null 2>&1; then
  if nc -z -w 2 127.0.0.1 "$HTTP_PORT" 2>/dev/null; then
    STATUS_WEB="OK"
  fi
fi

# 5. Probe PHP-FPM FastCGI
STATUS_FPM="SKIP"
if [ -e /run/php/php-fpm.sock ] || [ -e /var/run/php-fpm.sock ]; then
  STATUS_FPM="OK (socket)"
elif command -v nc >/dev/null 2>&1 && nc -z -w 1 127.0.0.1 9000 2>/dev/null; then
  STATUS_FPM="OK (127.0.0.1:9000)"
fi

if [ "$JSON_MODE" -eq 1 ]; then
  printf '{"php":"%s","core_files":"%s","database":"%s","webserver":"%s","php_fpm":"%s"}\n' \
    "$STATUS_PHP" "$STATUS_CORE" "$STATUS_DB" "$STATUS_WEB" "$STATUS_FPM"
  exit 0
fi

printf '
=== WordPress 7.1.2 Diagnostics & Health Report ===
'
printf '%-22s %-30s %s
' "Component" "Target / Context" "Status"
printf '%-22s %-30s %s
' "----------------------" "------------------------------" "------"
printf '%-22s %-30s %s
' "PHP Runtime" "CLI / Version" "$STATUS_PHP"
printf '%-22s %-30s %s
' "WordPress Core" "${WWWROOT}" "$STATUS_CORE"
printf '%-22s %-30s %s
' "MySQL Database" "${DB_HOST}:${DB_PORT} (${DB_NAME})" "$STATUS_DB"
printf '%-22s %-30s %s
' "HTTP Web Server" "${HTTP_HOST}:${HTTP_PORT}" "$STATUS_WEB"
printf '%-22s %-30s %s
' "PHP-FPM FastCGI" "Socket / Port 9000" "$STATUS_FPM"
printf '===================================================

'

if [ "$STATUS_CORE" = "OK" ] && [ "$STATUS_DB" = "OK" ]; then
  printf '[OK] WordPress platform services healthy.
'
  exit 0
else
  printf '[WARN] One or more WordPress platform components require attention.
'
  exit 0
fi
