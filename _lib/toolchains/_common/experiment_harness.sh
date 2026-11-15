#!/bin/sh
# ## Overview
# Backward-compatible forwarding shim sourcing canonical `_lib/_common/experiment/harness.sh`.
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/harness.sh"

set -feu
_eh_shim_caller_this="${THIS_FILE-}"
_eh_shim_caller_dir="${SCRIPT_DIR-}"
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
    [ -n "${_eh_shim_caller_this}" ] && THIS_FILE="${_eh_shim_caller_this}"
    [ -n "${_eh_shim_caller_dir}" ] && SCRIPT_DIR="${_eh_shim_caller_dir}"
    unset _eh_shim_caller_this _eh_shim_caller_dir || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

_eh_shim_self="${THIS_FILE}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/harness.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
STACK="${STACK%"${_eh_shim_self}":}"
export STACK
[ -n "${_eh_shim_caller_this}" ] && THIS_FILE="${_eh_shim_caller_this}"
[ -n "${_eh_shim_caller_dir}" ] && SCRIPT_DIR="${_eh_shim_caller_dir}"
unset _eh_shim_self _eh_shim_caller_this _eh_shim_caller_dir || true
