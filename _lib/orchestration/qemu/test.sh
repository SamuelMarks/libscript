#!/bin/sh
# ## Overview
# Test suite for QEMU component.
#
# ## Usage
# Execute this script to verify QEMU emulator installation and functionality.

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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  qemu-system-x86_64 --version
elif command -v qemu-system-aarch64 >/dev/null 2>&1; then
  qemu-system-aarch64 --version
elif command -v qemu-img >/dev/null 2>&1; then
  qemu-img --version
else
  printf '%s
' "QEMU binaries not found in PATH" >&2
  exit 1
fi

if [ -e "/dev/kvm" ]; then
  printf '%s
' "KVM device /dev/kvm found."
fi
