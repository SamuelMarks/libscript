#!/bin/sh
# ## Overview
# Test suite for the nodeenv component.
#
# ## Usage
# Execute this script to verify that nodeenv is accessible and reports its version.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  . "$SCRIPT_DIR/env.sh"
fi

if command -v nodeenv >/dev/null 2>&1; then
  nodeenv --version
  exit 0
else
  printf 'nodeenv binary not found in PATH
' >&2
  exit 1
fi
