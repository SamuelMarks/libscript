#!/bin/sh
# ## Overview
# Verifies Libseat functionality.
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

if [ -f /usr/lib/libseat.so ] || [ -f /usr/lib/libseat.so.1 ] || [ -f /lib/libseat.so.1 ] || [ -f /usr/include/libseat.h ]; then
  exit 0
fi

if command -v apk >/dev/null 2>&1 && apk info -e libseat >/dev/null 2>&1; then
  exit 0
fi

exit 1
