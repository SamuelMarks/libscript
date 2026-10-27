#!/bin/sh
# ## Overview
# Environment configuration for the LLVM Clang compiler.
# Exports CC, CXX, HOSTCC, CFLAGS, and prepends the managed Clang bin directory to PATH.
#
# ## Usage
# . ./_lib/languages/clang/env.sh

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

_clang_ver="${CLANG_VERSION:-default}"
_clang_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/clang/${_clang_ver}"
if [ ! -d "${_clang_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/clang/default" ]; then
  _clang_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/clang/default"
fi

if [ -d "${_clang_prefix}/bin" ]; then
  libscript_path_prepend "${_clang_prefix}/bin"
fi
if [ -x "${_clang_prefix}/bin/clang" ]; then
  libscript_path_prepend "${_clang_prefix}/bin"
  export CC="${_clang_prefix}/bin/clang"
elif command -v clang >/dev/null 2>&1; then
  CC="$(command -v clang)"
  export CC
else
  export CC='clang'
fi

if [ -x "${_clang_prefix}/bin/clang++" ]; then
  export CXX="${_clang_prefix}/bin/clang++"
elif command -v clang++ >/dev/null 2>&1; then
  CXX="$(command -v clang++)"
  export CXX
else
  export CXX='clang++'
fi

export HOSTCC="${CC}"
export CC_BACKEND='clang'
export CFLAGS="${CLANG_CFLAGS:--O2}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
