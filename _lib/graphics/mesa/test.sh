#!/bin/sh
# ## Overview
# Verifies Mesa functionality.
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

if [ -f /usr/lib/libgbm.so ] || [ -f /usr/lib/libgbm.so.1 ] || [ -f /usr/lib64/libgbm.so.1 ] || [ -f /usr/lib64/libgbm.so ] || [ -f /usr/lib/libGL.so ] || [ -f /usr/lib/libGL.so.1 ] || [ -f /usr/lib64/libGL.so.1 ] || [ -f /usr/lib64/libGL.so ] || [ -f /usr/lib/libEGL.so ] || [ -f /usr/lib/libEGL.so.1 ] || [ -f /usr/lib64/libEGL.so.1 ] || [ -f /usr/lib64/libEGL.so ]; then
  exit 0
fi

for _lib_dir in /usr/lib/*-linux-gnu* /usr/lib64; do
  if [ -f "${_lib_dir}/libgbm.so.1" ] || [ -f "${_lib_dir}/libGL.so.1" ] || [ -f "${_lib_dir}/libgbm.so" ] || [ -f "${_lib_dir}/libGL.so" ]; then
    exit 0
  fi
done

if command -v apk >/dev/null 2>&1 && apk info -e mesa >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && (dpkg-query -W -f='${Status}\n' libgbm1 2>/dev/null | grep -q 'install ok installed' || dpkg-query -W -f='${Status}\n' libgl1-mesa-dri 2>/dev/null | grep -q 'install ok installed'); then
  exit 0
fi

if command -v rpm >/dev/null 2>&1 && (rpm -q mesa-libGL >/dev/null 2>&1 || rpm -q mesa-libgbm >/dev/null 2>&1 || rpm -q mesa-dri-drivers >/dev/null 2>&1); then
  exit 0
fi

exit 1
