#!/bin/sh
# ## Overview
# Verifies Intel Media Driver installation and staging.
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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMP_FILE="${TARGET_SYSROOT}/var/lib/libscript/stamps/.stamp.intel-media-driver"

if [ -f "$STAMP_FILE" ]; then
  printf '[PASS] Intel Media Driver verified via stamp: %s
' "$STAMP_FILE"
  exit 0
fi

if command -v apk >/dev/null 2>&1 && apk info -e intel-media-driver >/dev/null 2>&1; then
  printf '[PASS] Intel Media Driver verified via apk
'
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && (dpkg-query -W -f='${Status}
' intel-media-va-driver 2>/dev/null | grep -q 'install ok installed' || dpkg-query -W -f='${Status}
' intel-media-va-driver-non-free 2>/dev/null | grep -q 'install ok installed'); then
  printf '[PASS] Intel Media Driver verified via dpkg
'
  exit 0
fi

for _lib_dir in /usr/lib/dri /usr/lib64/dri /usr/local/lib/dri /usr/lib/*-linux-gnu*/dri; do
  if [ -f "${_lib_dir}/iHD_drv_video.so" ]; then
    printf '[PASS] Intel Media Driver binary found: %s/iHD_drv_video.so
' "$_lib_dir"
    exit 0
  fi
done

printf '[FAIL] Intel Media Driver not found or not staged.
' >&2
exit 1
