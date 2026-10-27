#!/bin/sh
# ## Overview
# Verifies Musl libc functionality.
#
# ## Usage
# ./test.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || [ -f /lib/ld-musl-x86_64.so.1 ] || [ -f /lib/ld-musl-aarch64.so.1 ] || [ -f /usr/lib/libc.a ] || [ -f /usr/local/musl/lib/libc.a ] || command -v musl-gcc >/dev/null 2>&1; then
  exit 0
fi

for _lib_dir in /usr/lib/*-linux-musl*; do
  if [ -d "$_lib_dir" ]; then
    exit 0
  fi
done

if command -v apk >/dev/null 2>&1 && apk info -e musl >/dev/null 2>&1; then
  exit 0
fi

if command -v dpkg-query >/dev/null 2>&1 && (dpkg-query -W -f='${Status}
' musl 2>/dev/null | grep -q 'install ok installed' || dpkg-query -W -f='${Status}
' musl-tools 2>/dev/null | grep -q 'install ok installed'); then
  exit 0
fi

exit 1
