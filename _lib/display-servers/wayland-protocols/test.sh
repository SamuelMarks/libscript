#!/bin/sh
# ## Overview
# Verifies Wayland-Protocols functionality.
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

if [ -d /usr/share/wayland-protocols ] || [ -f /usr/share/pkgconfig/wayland-protocols.pc ] || [ -f /usr/lib/pkgconfig/wayland-protocols.pc ] || [ -f /usr/lib64/pkgconfig/wayland-protocols.pc ]; then
  exit 0
fi

if command -v apk >/dev/null 2>&1 && apk info -e wayland-protocols >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && dpkg-query -W -f='${Status}\n' wayland-protocols 2>/dev/null | grep -q 'install ok installed'; then
  exit 0
fi

if command -v rpm >/dev/null 2>&1 && (rpm -q wayland-protocols >/dev/null 2>&1 || rpm -q wayland-protocols-devel >/dev/null 2>&1); then
  exit 0
fi

exit 1
