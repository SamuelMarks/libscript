#!/bin/sh
# ## Overview
# Environment configuration for the EDG C/C++ Compiler Frontend (edgcpp).
# Exports CC, CXX, HOSTCC, CPFE_BIN, EDGCPP_HOME, CC_BACKEND, CXX_BACKEND, and prepends the edgcpp bin directory to PATH.
#
# ## Usage
# . ./_lib/languages/edgcpp/env.sh

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

_edg_ver="${EDGCPP_VERSION:-default}"
case "${_edg_ver}" in
  latest|stable|7.0|v7.0.1) _edg_ver="7.0.1" ;;
esac
_edg_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/${_edg_ver}"
if [ ! -d "${_edg_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default" ]; then
  _edg_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default"
elif [ ! -d "${_edg_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/7.0.1" ]; then
  _edg_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/7.0.1"
fi

export EDGCPP_HOME="${_edg_prefix}"

if [ -d "${_edg_prefix}/bin" ]; then
  libscript_path_prepend "${_edg_prefix}/bin"
fi

if [ -x "${_edg_prefix}/bin/cpfe" ]; then
  export CPFE_BIN="${_edg_prefix}/bin/cpfe"
fi

if [ -x "${_edg_prefix}/bin/edgcpp" ]; then
  export CC="${_edg_prefix}/bin/edgcpp"
elif [ -n "${EDGCPP_BIN:-}" ] && [ -x "${EDGCPP_BIN}" ]; then
  export CC="${EDGCPP_BIN}"
else
  export CC="${SCRIPT_DIR}/edgcpp_wrapper.sh"
fi

if [ -x "${_edg_prefix}/bin/edg-c++" ]; then
  export CXX="${_edg_prefix}/bin/edg-c++"
else
  export CXX="${SCRIPT_DIR}/edgcpp_wrapper.sh"
fi

export HOSTCC="${CC}"
export CC_BACKEND='edgcpp'
export CXX_BACKEND='edgcpp'
export EDGCPP_LOG_FILE="${EDGCPP_LOG_FILE:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/compile_events.jsonl}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
