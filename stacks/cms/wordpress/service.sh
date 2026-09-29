#!/bin/sh
# ## Overview
# Daemon lifecycle manager for WordPress 7.1.2 platform services.
# Coordinates startup, shutdown, and health status for Web Server (Nginx/Apache/Caddy)
# and PHP-FPM processes across systemd, rc.d, and launchd.
#
# ## Usage
#   ./service.sh <start|stop|restart|status>

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

ACTION="${1:-status}"
WEBSERVER="${WORDPRESS_WEBSERVER:-nginx}"

for s in "${WEBSERVER}" php-fpm; do
  if command -v systemctl >/dev/null 2>&1; then
    case "$ACTION" in
      start)
        systemctl start "$s" 2>/dev/null || true
        ;;
      stop)
        systemctl stop "$s" 2>/dev/null || true
        ;;
      restart)
        systemctl restart "$s" 2>/dev/null || true
        ;;
      status)
        systemctl status "$s" --no-pager 2>/dev/null || true
        ;;
    esac
  elif command -v service >/dev/null 2>&1; then
    service "$s" "$ACTION" 2>/dev/null || true
  fi
done

printf '[OK] Service action %s processed for WordPress stack.
' "$ACTION"
exit 0
