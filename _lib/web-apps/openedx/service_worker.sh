#!/bin/sh
# ## Overview
# Manages persistent background WSGI processes for Open edX LMS and Studio CMS.
#
# ## Usage
# ./_lib/web-apps/openedx/service_worker.sh [start|stop|status] [lms_port] [cms_port]

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

ACTION="${1:-status}"
OPENEDX_LMS_PORT="${2:-${OPENEDX_LMS_PORT:-8000}}"
OPENEDX_CMS_PORT="${3:-${OPENEDX_CMS_PORT:-8001}}"
export OPENEDX_LMS_PORT OPENEDX_CMS_PORT

# ## main
# Delegates service worker actions to service.sh.
main() {
  "${SCRIPT_DIR}/service.sh" "${ACTION}"
}

main "$@"
