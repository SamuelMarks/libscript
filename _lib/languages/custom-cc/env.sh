#!/bin/sh
# ## Overview
# Environment configuration for the Custom C Compiler (custom-cc).
# Exports CC, HOSTCC, CC_BACKEND, and prepends the custom-cc bin directory to PATH.
#
# ## Usage
# . ./_lib/languages/custom-cc/env.sh

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

_cc_ver="${CUSTOM_CC_VERSION:-default}"
_cc_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/custom-cc/${_cc_ver}"
if [ ! -d "${_cc_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/custom-cc/default" ]; then
  _cc_prefix="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/custom-cc/default"
fi

if [ -d "${_cc_prefix}/bin" ]; then
  libscript_path_prepend "${_cc_prefix}/bin"
fi

if [ -x "${_cc_prefix}/bin/custom-cc" ]; then
  export CC="${_cc_prefix}/bin/custom-cc"
elif [ -n "${CUSTOM_CC_BIN:-}" ] && [ -x "${CUSTOM_CC_BIN}" ]; then
  export CC="${CUSTOM_CC_BIN}"
else
  export CC="${SCRIPT_DIR}/cc_wrapper.sh"
fi

export HOSTCC="${CC}"
export CC_BACKEND='custom-cc'
export CUSTOM_CC_LOG_FILE="${CUSTOM_CC_LOG_FILE:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/custom-cc/compile_events.jsonl}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
