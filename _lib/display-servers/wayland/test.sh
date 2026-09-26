#!/bin/sh
# ## Overview
# Verifies Wayland Protocol functionality.
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

if [ -f /usr/lib/libwayland-client.so.0 ] || [ -f /usr/lib64/libwayland-client.so.0 ] || [ -f /lib/libwayland-client.so.0 ]; then
  exit 0
fi

for _lib_dir in /usr/lib/*-linux-gnu* /usr/lib64; do
  if [ -f "${_lib_dir}/libwayland-client.so.0" ]; then
    exit 0
  fi
done

if command -v wayland-scanner >/dev/null 2>&1; then
  exit 0
fi

if command -v apk >/dev/null 2>&1 && apk info -e wayland-libs-client >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Status}\n' libwayland-client0 2>/dev/null | grep -q 'install ok installed'; then
  exit 0
fi

if command -v rpm >/dev/null 2>&1 && (rpm -q libwayland-client >/dev/null 2>&1 || rpm -q wayland-devel >/dev/null 2>&1); then
  exit 0
fi

exit 1
