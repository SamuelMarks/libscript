#!/bin/sh
# ## Overview
# Environment variable initialization script for the nodeenv component.
# Sets up PATH to discover nodeenv binaries.
#
# ## Usage
# Source this script to load the environment variables.

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

NODEENV_VERSION="${NODEENV_VERSION:-latest}"
if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/nodeenv/${NODEENV_VERSION}/bin" ]; then
  libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/nodeenv/${NODEENV_VERSION}/bin"
fi
STACK="${STACK%"${THIS_FILE}":}"
export STACK
