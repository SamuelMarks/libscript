#!/bin/sh
# ## Overview
# Environment configuration for the Tiny C Compiler (TCC).
# Exports CC, HOSTCC, CFLAGS, and prepends the managed TCC bin directory to PATH.
#
# ## Usage
# . ./_lib/languages/tcc/env.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

_tcc_ver="${TCC_VERSION:-default}"
_tcc_prefix="${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/${_tcc_ver}"
if [ ! -d "${_tcc_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/default" ]; then
  _tcc_prefix="${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/default"
fi

if [ -d "${_tcc_prefix}/bin" ]; then
  export PATH="${_tcc_prefix}/bin:${PATH}"
fi

if [ -x "${_tcc_prefix}/bin/tcc" ]; then
  export CC="${_tcc_prefix}/bin/tcc"
elif command -v tcc >/dev/null 2>&1; then
  CC="$(command -v tcc)"
  export CC
else
  export CC="tcc"
fi

export HOSTCC="${CC}"
export CC_BACKEND="tcc"
export CFLAGS="${TCC_CFLAGS:--O2}"
