#!/bin/sh
# ## Overview
# Wrapper script to detect existing databases and set MSI installer properties via standard exit codes.
# This script wraps libscript status calls to interface with CustomActions and healthchecks cleanly.
#
# ## Usage
# ./status_databases.sh <component>

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

if [ -z "${1-}" ]; then
  printf '[ERROR] Missing component argument.
' >&2
  exit 1
fi
COMPONENT="$1"

if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" status "${COMPONENT}" >/dev/null 2>&1; then
  exit 0
else
  exit 1
fi
