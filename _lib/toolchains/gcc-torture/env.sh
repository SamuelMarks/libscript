#!/bin/sh
# ## Overview
# Environment configuration script for gcc-torture.
#
# ## Usage
# Source this script to prepend the isolated gcc-torture bin directory to PATH.
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

GCC_TORTURE_VERSION="${GCC_TORTURE_VERSION:-14.2.0}"
if [ "${GCC_TORTURE_VERSION}" = "latest" ]; then
  EXACT_VERSION='latest'
else
  EXACT_VERSION="${GCC_TORTURE_VERSION}"
fi

_gt_base="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gcc-torture/${EXACT_VERSION}"
if [ -d "${_gt_base}/gcc/testsuite/gcc.c-torture/execute" ]; then
  export GCC_TORTURE_DIR="${_gt_base}/gcc/testsuite/gcc.c-torture/execute"
else
  export GCC_TORTURE_DIR="${GCC_TORTURE_DIR:-${_gt_base}/execute}"
fi
libscript_path_prepend "${_gt_base}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
