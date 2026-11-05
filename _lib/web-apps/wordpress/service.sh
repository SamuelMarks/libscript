#!/bin/sh
# ## Overview
# Daemon lifecycle manager for WordPress 7.1.2 platform services.
# Coordinates startup, shutdown, and health status for Web Server (Nginx/Apache/Caddy)
# and PHP-FPM processes across systemd, rc.d, and launchd.
# ## Usage
#   ./service.sh <start|stop|restart|status>

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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

ACTION="${1:-status}"
WEBSERVER="${WORDPRESS_WEBSERVER:-nginx}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

for s in "${WEBSERVER}" php-fpm; do
  libscript_service "$ACTION" "$s" 2>/dev/null || true
done

printf '[OK] Service action %s processed for WordPress stack.\n' "$ACTION"
exit 0
