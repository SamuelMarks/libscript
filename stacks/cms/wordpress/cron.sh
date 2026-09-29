#!/bin/sh
# ## Overview
# Host-native background cron task runner and scheduler manager for WordPress 7.1.2.
# Offloads periodic WP-Cron tasks from HTTP web traffic to system crontab.
#
# ## Usage
#   ./cron.sh <run|install|uninstall|status>

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
CMD="${1:-run}"

case "$CMD" in
  run)
    if command -v wp >/dev/null 2>&1; then
      wp --path="$WWWROOT" cron event run --due-now 2>/dev/null || true
    elif [ -f "${WWWROOT}/wp-cron.php" ] && command -v php >/dev/null 2>&1; then
      php "${WWWROOT}/wp-cron.php" >/dev/null 2>&1 || true
    fi
    printf '[OK] WordPress cron execution completed.
'
    ;;
  install)
    CRON_LINE="*/5 * * * * cd ${WWWROOT} && php wp-cron.php >/dev/null 2>&1"
    if command -v crontab >/dev/null 2>&1; then
      ( crontab -l 2>/dev/null | grep -v 'wp-cron\.php' || true; printf '%s
' "$CRON_LINE" ) | crontab -
      printf '[OK] Registered WP-Cron scheduler in system crontab.
'
    else
      printf '[WARN] crontab command not available on this host.
'
    fi
    ;;
  uninstall)
    if command -v crontab >/dev/null 2>&1; then
      crontab -l 2>/dev/null | grep -v 'wp-cron\.php' | crontab - 2>/dev/null || true
      printf '[OK] Removed WP-Cron scheduler from system crontab.
'
    fi
    ;;
  status)
    if command -v crontab >/dev/null 2>&1; then
      crontab -l 2>/dev/null | grep 'wp-cron\.php' || printf '[INFO] No WP-Cron entry found in crontab.
'
    fi
    ;;
  help|--help|-h)
    cat << 'EOF_HELP'
WordPress Cron Management

Usage:
  ./cron.sh run        Execute pending due cron events immediately
  ./cron.sh install    Register 5-minute periodic task in system crontab
  ./cron.sh uninstall  Remove periodic task from system crontab
  ./cron.sh status     Inspect current crontab registration
EOF_HELP
    exit 0
    ;;
  *)
    printf '[ERROR] Unknown cron command: %s
' "$CMD" >&2
    exit 1
    ;;
esac
