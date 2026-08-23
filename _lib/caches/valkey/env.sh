#!/bin/sh
# ## Overview
# Defines environment variables for the Valkey Cache component on Unix systems.
# It ensures `VALKEY_BUILD_DIR` is appropriately configured for source compilation paths.
# 
# ## Usage
# Source this file to apply Valkey's environment variables.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
export VALKEY_BUILD_DIR="${VALKEY_BUILD_DIR:-${BUILD_DIR:-${TMPDIR:-/tmp}}/valkey}"

VALKEY_INSTALL_METHOD="${VALKEY_INSTALL_METHOD:-system}"
export VALKEY_INSTALL_METHOD

VALKEY_VERSION="${VALKEY_VERSION:-latest}"
export PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/valkey/${VALKEY_VERSION}/bin:${PATH}"
