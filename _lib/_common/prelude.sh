#!/bin/sh
# ## Overview
# Common preamble and initialization logic shared across scripts.
# 
# ## Usage
# This script is intended to be sourced by other scripts, not executed directly.


set -feu
_prelude_caller_this="${THIS_FILE:-}"; _prelude_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_prelude_caller_this" ] && THIS_FILE="$_prelude_caller_this"
    [ -n "$_prelude_caller_dir" ] && SCRIPT_DIR="$_prelude_caller_dir"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

export LIBSCRIPT_ROOT_DIR

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: ${THIS_FILE##*/}"
  exit 0
fi

LIBSCRIPT_BUILD_DIR="${LIBSCRIPT_BUILD_DIR:-${TMPDIR:-/tmp}/libscript_build}"
export LIBSCRIPT_BUILD_DIR

LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

PATH="${HOME}"'/.cargo/bin:'"${LIBSCRIPT_DATA_DIR}"'/bin:'"${PATH}"
export PATH

[ -d "${LIBSCRIPT_BUILD_DIR}" ] || mkdir -p -- "${LIBSCRIPT_BUILD_DIR}"
[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_prelude_caller_dir:-}" ] && SCRIPT_DIR="$_prelude_caller_dir"
[ -n "${_prelude_caller_this:-}" ] && THIS_FILE="$_prelude_caller_this"
unset _prelude_caller_this _prelude_caller_dir || true
