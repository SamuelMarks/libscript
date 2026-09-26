#!/bin/sh
# ## Overview
# Verifies Vulkan Loader on Unix/Linux.
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

if [ -f "/usr/lib/libvulkan.so" ] || [ -f "/usr/lib/libvulkan.so.1" ] || [ -f "/usr/lib64/libvulkan.so" ] || [ -f "/usr/lib64/libvulkan.so.1" ] || [ -f "/usr/local/lib/libvulkan.so" ] || command -v vulkaninfo >/dev/null 2>&1; then
  printf '[OK] Vulkan loader verified
'
else
  printf '[SKIP] Vulkan loader not installed
'
fi
exit 0
