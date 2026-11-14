#!/bin/sh
# ## Overview
# Environment configuration script for llvm, exposing llvm-cov, llvm-profdata, llvm-strip, and llvm-objdump.
#
# ## Usage
# Source this script to prepend the isolated llvm bin directory (and system LLVM bin fallback) to PATH.
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

LLVM_VERSION="${LLVM_VERSION:-latest}"
if [ "${LLVM_VERSION}" = "latest" ]; then
  EXACT_VERSION='latest'
else
  EXACT_VERSION="${LLVM_VERSION}"
fi

for _llvm_sys in '/opt/homebrew/opt/llvm/bin' '/usr/local/opt/llvm/bin'; do
  if [ -d "${_llvm_sys}" ]; then
    libscript_path_prepend "${_llvm_sys}"
  fi
done
_llvm_iso="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/llvm/${EXACT_VERSION}"
if [ -d "${_llvm_iso}/bin" ]; then
  export LLVM_PREFIX="${LLVM_PREFIX:-${_llvm_iso}}"
elif [ -d '/opt/homebrew/opt/llvm/bin' ]; then
  export LLVM_PREFIX="${LLVM_PREFIX:-/opt/homebrew/opt/llvm}"
elif [ -d '/usr/local/opt/llvm/bin' ]; then
  export LLVM_PREFIX="${LLVM_PREFIX:-/usr/local/opt/llvm}"
fi
libscript_path_prepend "${_llvm_iso}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
