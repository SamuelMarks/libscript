#!/bin/sh
# ## Overview
# Checks if a given service is actively running via the native init system.
#
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/status_service.sh"
# check_service_status "postgresql"

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE[0]-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
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
export LIBSCRIPT_ROOT_DIR

check_service_status() {
    OS_NAME=$(uname -s)
    for svc in "$@"; do
        if [ "$OS_NAME" = "Linux" ]; then
            if command -v systemctl >/dev/null 2>&1; then
                if systemctl is-active --quiet "$svc"; then
                    
                    return 0
                fi
            elif command -v service >/dev/null 2>&1; then
                if service "$svc" status >/dev/null 2>&1; then
                    
                    return 0
                fi
            fi
        elif [ "$OS_NAME" = "SunOS" ]; then
            if command -v svcs >/dev/null 2>&1; then
                if svcs -H -o state "$svc" 2>/dev/null | grep -q "^online"; then
                    
                    return 0
                fi
            fi
        elif [ "$OS_NAME" = "FreeBSD" ]; then
            if command -v service >/dev/null 2>&1; then
                if service "$svc" onestatus >/dev/null 2>&1 || service "$svc" status >/dev/null 2>&1; then
                    
                    return 0
                fi
            fi
        elif [ "$OS_NAME" = "Darwin" ]; then
            if command -v launchctl >/dev/null 2>&1; then
                if launchctl print "system/$svc" >/dev/null 2>&1 || launchctl list | grep -q "$svc"; then
                    
                    return 0
                fi
            fi
        fi
    done
    
    return 1
}
