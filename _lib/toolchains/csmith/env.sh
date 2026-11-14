#!/bin/sh
# ## Overview
# Environment configuration script for csmith.
#
# ## Usage
# Source this script to prepend the isolated csmith bin directory to PATH.
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

CSMITH_VERSION="${CSMITH_VERSION:-2.3.0}"
if [ "${CSMITH_VERSION}" = "latest" ]; then
  EXACT_VERSION='latest'
else
  EXACT_VERSION="${CSMITH_VERSION}"
fi

_csmith_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/csmith/${EXACT_VERSION}"
if [ -d "${_csmith_dir}/include" ]; then
  export CSMITH_HOME="${_csmith_dir}"
elif [ -d '/opt/homebrew/opt/csmith/include' ]; then
  export CSMITH_HOME='/opt/homebrew/opt/csmith'
elif [ -d '/usr/include/csmith-2.3.0' ]; then
  export CSMITH_HOME='/usr'
else
  export CSMITH_HOME="${_csmith_dir}"
fi
libscript_path_prepend "${_csmith_dir}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
