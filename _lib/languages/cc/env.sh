#!/bin/sh
# ## Overview
# Environment initialization for the Unified C Compiler Router (cc).
# Routes to the selected CC_BACKEND ('gcc', 'clang', 'tcc', 'custom-cc', or 'default').
#
# ## Usage
# . ./_lib/languages/cc/env.sh

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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
export LIBSCRIPT_ROOT_DIR

export CC_INSTALL_METHOD="${CC_INSTALL_METHOD:-system}"
CC_VERSION="${CC_VERSION:-latest}"
_backend="${CC_BACKEND:-default}"

if [ "${_backend}" != "default" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/${_backend}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/${_backend}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
else
  libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/cc/${CC_VERSION}/bin"
  if command -v cc >/dev/null 2>&1; then
    CC="$(command -v cc)"
    export CC
  elif command -v gcc >/dev/null 2>&1; then
    CC="$(command -v gcc)"
    export CC
  elif command -v clang >/dev/null 2>&1; then
    CC="$(command -v clang)"
    export CC
  fi
fi
STACK="${STACK%"${THIS_FILE}":}"
export STACK
