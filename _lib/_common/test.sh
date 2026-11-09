#!/bin/sh
# ## Overview
# Serves as the primary Unix test entry point for components, loading the common testing framework.
# ## Usage
# Execute this script to trigger component testing on Unix systems.
set -feu
_common_test_caller_this="${THIS_FILE:-}"; _common_test_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_common_test_caller_this" ] && THIS_FILE="$_common_test_caller_this"
    [ -n "$_common_test_caller_dir" ] && SCRIPT_DIR="$_common_test_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
_common_test_this="${THIS_FILE}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="${_common_test_this}"
log_info 'Common loaded successfully'
STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_common_test_caller_dir:-}" ] && SCRIPT_DIR="$_common_test_caller_dir"
[ -n "${_common_test_caller_this:-}" ] && THIS_FILE="$_common_test_caller_this"
unset SCRIPT_NAME _common_test_caller_this _common_test_caller_dir _common_test_this || true
