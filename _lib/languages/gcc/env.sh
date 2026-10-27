#!/bin/sh
# ## Overview
# Environment configuration for the GNU Compiler Collection (GCC).
# Exports CC, CXX, HOSTCC, CFLAGS, and prepends the managed GCC bin directory to PATH.
#
# ## Usage
# . ./_lib/languages/gcc/env.sh

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

_gcc_ver="${GCC_VERSION:-default}"
_gcc_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gcc/${_gcc_ver}"
if [ ! -d "${_gcc_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gcc/default" ]; then
  _gcc_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gcc/default"
fi

if [ -d "${_gcc_prefix}/bin" ]; then
  libscript_path_prepend "${_gcc_prefix}/bin"
fi
if [ -x "${_gcc_prefix}/bin/gcc" ]; then
  libscript_path_prepend "${_gcc_prefix}/bin"
  export CC="${_gcc_prefix}/bin/gcc"
elif command -v gcc >/dev/null 2>&1; then
  CC="$(command -v gcc)"
  export CC
else
  export CC='gcc'
fi

if [ -x "${_gcc_prefix}/bin/g++" ]; then
  export CXX="${_gcc_prefix}/bin/g++"
elif command -v g++ >/dev/null 2>&1; then
  CXX="$(command -v g++)"
  export CXX
else
  export CXX='g++'
fi

export HOSTCC="${CC}"
export CC_BACKEND='gcc'
export CFLAGS="${GCC_CFLAGS:--O2}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
