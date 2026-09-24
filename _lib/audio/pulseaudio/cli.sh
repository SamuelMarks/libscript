#!/bin/sh
# ## Overview
# Command-line interface entry point for PulseAudio sound server.
#
# ## Usage
# ./cli.sh [action]

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
export STACK="${STACK:-}${THIS_FILE}:"

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
PACKAGE_NAME="pulseaudio"
export PACKAGE_NAME

exec sh "${SCRIPT_DIR}/../../_common/component_core.sh" "$@"
