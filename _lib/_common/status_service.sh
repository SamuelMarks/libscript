#!/bin/sh
# ## Overview
# Checks if a given service is actively running via the native init system.
# ## Usage
# . "$LIBSCRIPT_ROOT_DIR/_lib/_common/status_service.sh"
# check_service_status "postgresql"
set -feu
_status_service_caller_this="${THIS_FILE:-}"; _status_service_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_status_service_caller_this" ] && THIS_FILE="$_status_service_caller_this"
    [ -n "$_status_service_caller_dir" ] && SCRIPT_DIR="$_status_service_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# ## check_service_status
# Queries the active init system or daemon manager via libscript_service to verify whether a service is running.
check_service_status() {
    for svc in "$@"; do
        if libscript_service is-active "$svc" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_status_service_caller_dir:-}" ] && SCRIPT_DIR="$_status_service_caller_dir"
[ -n "${_status_service_caller_this:-}" ] && THIS_FILE="$_status_service_caller_this"
unset _status_service_caller_this _status_service_caller_dir || true
