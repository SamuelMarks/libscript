#!/bin/sh
# ## Overview
# Environment initialization for Zig.
#
# ## Usage
# Sets up `ZIG_VERSION` and prepends Zig to PATH.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

ZIG_VERSION="${ZIG_VERSION:-0.12.0}"
if [ "${ZIG_VERSION}" = "latest" ]; then
  EXACT_VERSION="0.12.0"
else
  EXACT_VERSION="${ZIG_VERSION}"
fi

export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/${EXACT_VERSION}:${PATH}"
