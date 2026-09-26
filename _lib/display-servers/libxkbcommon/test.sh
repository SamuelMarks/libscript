#!/bin/sh
# ## Overview
# Verifies Libxkbcommon functionality.
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

if [ -f /usr/lib/libxkbcommon.so ] || [ -f /usr/lib/libxkbcommon.so.0 ] || [ -f /usr/lib64/libxkbcommon.so.0 ] || [ -f /usr/lib64/libxkbcommon.so ] || [ -f /lib/libxkbcommon.so.0 ] || [ -d /usr/include/xkbcommon ]; then
  exit 0
fi

for _lib_dir in /usr/lib/*-linux-gnu* /usr/lib64; do
  if [ -f "${_lib_dir}/libxkbcommon.so.0" ] || [ -f "${_lib_dir}/libxkbcommon.so" ]; then
    exit 0
  fi
done

if command -v apk >/dev/null 2>&1 && apk info -e libxkbcommon >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && (dpkg-query -W -f='${Status}\n' libxkbcommon0 2>/dev/null | grep -q 'install ok installed' || dpkg-query -W -f='${Status}\n' libxkbcommon 2>/dev/null | grep -q 'install ok installed'); then
  exit 0
fi

if command -v rpm >/dev/null 2>&1 && rpm -q libxkbcommon >/dev/null 2>&1; then
  exit 0
fi

exit 1
