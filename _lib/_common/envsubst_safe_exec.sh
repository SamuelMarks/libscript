#!/bin/sh
# ## Overview
# Executable wrapper for the `envsubst_safe` utility function.
# This script exposes the `envsubst_safe` POSIX/awk logic so it can be called
# directly as a shell command (e.g. within pipes or as a standalone script) 
# rather than sourced as a library function.
# 
# ## Usage
# `./envsubst_safe_exec.sh [file_path]` or `echo "..." | ./envsubst_safe_exec.sh`


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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

SCRIPT_NAME="${DIR}"'/envsubst_safe.sh'
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

envsubst_safe "$@"
