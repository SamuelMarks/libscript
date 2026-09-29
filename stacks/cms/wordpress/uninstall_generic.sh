#!/bin/sh
# ## Overview
# Provides an enterprise-grade, clean uninstallation mechanism for WordPress 7.1.2.
# Removes web server virtual host configs, unlinks crontab schedules, removes WordPress
# web document root, and drops the isolated wordpress database schema while strictly
# preserving any shared Open edX MySQL server and databases.
#
# ## Usage
#   ./uninstall_generic.sh [--purge-db]

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
SERVER_NAME="${WORDPRESS_SERVER_NAME:-wordpress.local}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"

# 1. Remove scheduled cron entries
if [ -x "${SCRIPT_DIR}/cron.sh" ]; then
  "${SCRIPT_DIR}/cron.sh" uninstall >/dev/null 2>&1 || true
fi

# 2. Remove webserver configs
priv rm -f "/etc/nginx/http.d/${SERVER_NAME}.conf" \
           "/etc/nginx/conf.d/${SERVER_NAME}.conf" \
           "/etc/nginx/sites-available/${SERVER_NAME}.conf" \
           "/etc/nginx/sites-enabled/${SERVER_NAME}.conf" \
           "/etc/caddy/conf.d/${SERVER_NAME}.caddy" 2>/dev/null || true

# 3. Clean up database if --purge-db specified
if [ "${1:-}" = "--purge-db" ]; then
  _client="mysql"
  command -v mariadb >/dev/null 2>&1 && _client="mariadb"
  if command -v "$_client" >/dev/null 2>&1; then
    printf '[INFO] Purging WordPress database schema without touching Open edX...\n'
    priv "$_client" -u root -e \
      "DROP DATABASE IF EXISTS \`${DB_NAME}\`;
       DROP USER IF EXISTS '${DB_USER}'@'localhost';
       DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';
       FLUSH PRIVILEGES;" 2>/dev/null || true
  fi
fi

# 4. Remove WWWROOT files
if [ -d "$WWWROOT" ]; then
  printf '[INFO] Removing WordPress document root: %s...
' "$WWWROOT"
  priv rm -rf "$WWWROOT"
fi

printf '[OK] WordPress uninstallation completed successfully.
'
exit 0
