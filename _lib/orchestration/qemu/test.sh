#!/bin/sh
# ## Overview
# Test suite for QEMU component.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  qemu-system-x86_64 --version
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
