#!/bin/sh
# ## Overview
# Database console and query execution tool for WordPress 7.1.2.
# Extracts connection credentials from wp-config.php and launches an interactive shell
# or executes non-interactive SQL queries, exports, and imports.
#
# ## Usage
#   ./dbshell.sh [query <sql>|export <file.sql>|import <file.sql>|help]

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

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="wordpress"
DB_USER="wordpress"
DB_PASSWORD="wordpress"
DB_SSL_CA=""

# Parse wp-config.php if present
if [ -f "$WP_CONFIG" ]; then
  _val=$(grep "define( *'DB_NAME'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_NAME' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_NAME="$_val"
  _val=$(grep "define( *'DB_USER'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_USER' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_USER="$_val"
  _val=$(grep "define( *'DB_PASSWORD'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'DB_PASSWORD' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_PASSWORD="$_val"
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
  _val=$(grep "define( *'MYSQL_SSL_CA'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'MYSQL_SSL_CA' *, *'([^']*)'.*/\1/" || true)
  [ -n "$_val" ] && DB_SSL_CA="$_val"
fi

# Locate client binary
CLIENT="mysql"
command -v mariadb >/dev/null 2>&1 && CLIENT="mariadb"
DUMP_CLIENT="mysqldump"
command -v mariadb-dump >/dev/null 2>&1 && DUMP_CLIENT="mariadb-dump"

if ! command -v "$CLIENT" >/dev/null 2>&1; then
  printf '[ERROR] No MySQL/MariaDB client executable found in PATH.
' >&2
  exit 1
fi

SSL_FLAGS=""
if [ -n "$DB_SSL_CA" ] && [ -f "$DB_SSL_CA" ]; then
  SSL_FLAGS="--ssl-ca=${DB_SSL_CA}"
fi

export MYSQL_PWD="${DB_PASSWORD}"

CMD="${1:-interactive}"

case "$CMD" in
  interactive|"")
    # shellcheck disable=SC2086
    exec "$CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" $SSL_FLAGS "$DB_NAME"
    ;;
  query|sql)
    shift
    if [ $# -lt 1 ]; then
      printf '[ERROR] Usage: %s query "<sql_statement>"
' "$THIS_FILE" >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    exec "$CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" $SSL_FLAGS -e "$1" "$DB_NAME"
    ;;
  export)
    shift
    OUT_FILE="${1:-wordpress_dump_$(date +%Y%m%d_%H%M%S).sql}"
    # shellcheck disable=SC2086
    "$DUMP_CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" $SSL_FLAGS --single-transaction --quick "$DB_NAME" > "$OUT_FILE"
    printf '[OK] WordPress database exported to %s
' "$OUT_FILE"
    ;;
  import)
    shift
    if [ $# -lt 1 ] || [ ! -f "$1" ]; then
      printf '[ERROR] Usage: %s import <file.sql>
' "$THIS_FILE" >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    "$CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" $SSL_FLAGS "$DB_NAME" < "$1"
    printf '[OK] WordPress database imported from %s
' "$1"
    ;;
  help|--help|-h)
    cat << 'EOF_HELP'
WordPress Database Shell & Query Console

Usage:
  ./dbshell.sh                     Launch interactive MySQL client connected to WordPress DB
  ./dbshell.sh query "<sql>"       Execute non-interactive SQL query
  ./dbshell.sh export [file.sql]   Export full database dump
  ./dbshell.sh import <file.sql>   Import database dump from SQL file
EOF_HELP
    exit 0
    ;;
  *)
    # Treat as query or arguments
    # shellcheck disable=SC2086
    exec "$CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" $SSL_FLAGS "$DB_NAME" "$@"
    ;;
esac
