#!/bin/sh
# ## Overview
# Environment configuration for msvc, exporting MSVC_ARCH, MSVC_CRT, and MSVC_DARICE_CUB_PATH.
#
# ## Usage
# Source this script to configure environment variables.

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

export MSVC_ARCH="${MSVC_ARCH:-x64}"
export MSVC_CRT="${MSVC_CRT:-MD}"
export MSVC_DARICE_CUB_PATH="${MSVC_DARICE_CUB_PATH:-}"

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
