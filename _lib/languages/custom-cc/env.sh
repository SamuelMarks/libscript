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

_cc_ver="${CUSTOM_CC_VERSION:-default}"
_cc_prefix="${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/${_cc_ver}"
if [ ! -d "${_cc_prefix}" ] && [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/default" ]; then
  _cc_prefix="${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/default"
fi

if [ -d "${_cc_prefix}/bin" ]; then
  export PATH="${_cc_prefix}/bin:${PATH}"
fi

if [ -x "${_cc_prefix}/bin/custom-cc" ]; then
  export CC="${_cc_prefix}/bin/custom-cc"
elif [ -n "${CUSTOM_CC_BIN:-}" ] && [ -x "${CUSTOM_CC_BIN}" ]; then
  export CC="${CUSTOM_CC_BIN}"
else
  export CC="${SCRIPT_DIR}/cc_wrapper.sh"
fi

export HOSTCC="${CC}"
export CC_BACKEND="custom-cc"
export CUSTOM_CC_LOG_FILE="${CUSTOM_CC_LOG_FILE:-${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/compile_events.jsonl}"
