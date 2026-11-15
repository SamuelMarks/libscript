#!/bin/sh
# ## Overview
# Environment configuration script for gemma-tpu-suite.
#
# ## Usage
# Source this script to prepend the isolated gemma-tpu-suite bin directory to PATH.
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

: "${GEMMA_TPU_SUITE_VERSION:=1.0.0}"
EXACT_VERSION="${GEMMA_TPU_SUITE_VERSION}"
if [ "${EXACT_VERSION}" = 'latest' ] || [ "${EXACT_VERSION}" = 'stable' ]; then
  EXACT_VERSION='1.0.0'
fi
libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gemma-tpu-suite/${EXACT_VERSION}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
