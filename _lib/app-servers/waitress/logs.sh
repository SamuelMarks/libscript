#!/bin/sh
# ## Overview
# Logs reader for app-servers/waitress.
#
# ## Usage
# ./logs.sh [tail|-f]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

if [ -f "$SCRIPT_DIR/env.sh" ]; then
  SCRIPT_NAME="$SCRIPT_DIR/env.sh"
  export SCRIPT_NAME
  . "$SCRIPT_NAME"
fi

SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/logs_service.sh"
export SCRIPT_NAME
. "$SCRIPT_NAME"

read_logs "$*" "waitress" ""
