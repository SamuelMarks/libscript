#!/bin/sh
# ## Overview
# Wrapper script to detect existing databases and set MSI installer properties via standard exit codes.
# This script wraps libscript status calls to interface with CustomActions cleanly.
#
# ## Usage
# ./status_databases.sh <component>
#
# ## Parameters
# $1 - Component name (e.g., databases/mysql)

set -eu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="$0"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

SCRIPT_DIR="$(cd "$(dirname "${THIS_FILE}")" && pwd)"
LIBSCRIPT_ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

if [ -z "${1-}" ]; then
    printf "[ERROR] Missing component argument.\n" >&2
    exit 1
fi
COMPONENT="$1"

if "${LIBSCRIPT_ROOT_DIR}/libscript.sh" status "${COMPONENT}" >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi