#!/bin/sh
# ## Overview
# Common preamble and initialization logic shared across scripts.
# 
# ## Usage
# This script is intended to be sourced by other scripts, not executed directly.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
_RAW_DIR="$(cd "$(dirname -- "${THIS_FILE}")" && pwd)"

# If THIS_FILE resolves to netctl.sh, its dirname is the root. If it resolves to LIB/prelude.sh, its dirname is LIB.
case "$_RAW_DIR" in
  */LIB) NETCTL_DIR="${NETCTL_DIR:-${_RAW_DIR%/*}}" ;;
  *) NETCTL_DIR="${NETCTL_DIR:-$_RAW_DIR}" ;;
esac

export NETCTL_DIR
