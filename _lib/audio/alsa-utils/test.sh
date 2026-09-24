#!/bin/sh
# ## Overview
# Verifies Alsa-Utils functionality.
#
# ## Usage
# ./test.sh

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

command -v aplay >/dev/null 2>&1 || command -v amixer >/dev/null 2>&1 || command -v alsamixer >/dev/null 2>&1 || exit 1
aplay --version >/dev/null 2>&1 || amixer --version >/dev/null 2>&1 || true
exit 0
