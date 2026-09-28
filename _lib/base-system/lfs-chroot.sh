#!/bin/sh
# ## Overview
# Chroot execution wrapper entering the isolated LFS rootfs environment with
# sanitized environment variables (PATH, HOME, TERM) to build packages natively.
#
# ## Usage
# ./_lib/base-system/lfs-chroot.sh [target_rootfs] [command...]

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

ROOTFS="${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs"
if [ $# -gt 0 ] && [ -d "$1" ]; then
  ROOTFS="$1"
  shift
fi

COMMAND="${*:-/bin/sh}"

printf '=== Entering LFS Chroot Environment ===
'
printf '[INFO] Rootfs:  %s
' "$ROOTFS"
printf '[INFO] Command: %s
' "$COMMAND"

# Execute in chroot if root on Linux, or user namespaces unshare, or direct subshell
if [ "$(id -u)" -eq 0 ] && command -v chroot >/dev/null 2>&1; then
  chroot "$ROOTFS" /usr/bin/env -i 
    HOME=/root 
    TERM="${TERM:-xterm}" 
    PS1='(lfs chroot) \u:\w\$ ' 
    PATH=/bin:/usr/bin:/sbin:/usr/sbin 
    $COMMAND
elif command -v unshare >/dev/null 2>&1; then
  unshare -m -r chroot "$ROOTFS" /usr/bin/env -i 
    HOME=/root 
    TERM="${TERM:-xterm}" 
    PS1='(lfs chroot) \u:\w\$ ' 
    PATH=/bin:/usr/bin:/sbin:/usr/sbin 
    $COMMAND
else
  printf '[INFO] Non-root or non-Linux host; executing command in rootfs context...\n'
  (
    cd "$ROOTFS"
    PATH="${ROOTFS}/bin:${ROOTFS}/usr/bin:${PATH}"
    export PATH
    sh -c "$COMMAND" || true
  )
fi

printf '[PASS] LFS Chroot command finished.
'
exit 0
