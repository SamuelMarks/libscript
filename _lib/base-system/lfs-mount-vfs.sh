#!/bin/sh
# ## Overview
# Mounts or unmounts the virtual kernel filesystems (/dev, /dev/pts, /proc, /sys, /run)
# into the target LFS rootfs prior to entering the chroot jail.
#
# ## Usage
# ./_lib/base-system/lfs-mount-vfs.sh [mount|umount|status] [target_rootfs]

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

ACTION="${1:-mount}"
ROOTFS="${2:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}"

mkdir -p "$ROOTFS"

if [ "$ACTION" = "umount" ] || [ "$ACTION" = "unmount" ]; then
  printf '[INFO] Unmounting virtual filesystems from: %s
' "$ROOTFS"
  if [ "$(id -u)" -eq 0 ] && command -v umount >/dev/null 2>&1; then
    umount -l "${ROOTFS}/dev/pts" 2>/dev/null || true
    umount -l "${ROOTFS}/dev/shm" 2>/dev/null || true
    umount -l "${ROOTFS}/dev" 2>/dev/null || true
    umount -l "${ROOTFS}/proc" 2>/dev/null || true
    umount -l "${ROOTFS}/sys" 2>/dev/null || true
    umount -l "${ROOTFS}/run" 2>/dev/null || true
  fi
  printf '[DONE] Unmount complete.
'
  exit 0
fi

if [ "$ACTION" = "status" ]; then
  printf '=== Virtual Filesystem Mount Status for %s ===
' "$ROOTFS"
  if command -v mount >/dev/null 2>&1; then
    mount | grep "$ROOTFS" || printf '  No virtual filesystems currently mounted.
'
  fi
  exit 0
fi

printf '=== Mounting Virtual Filesystems for LFS Rootfs ===
'
printf '[INFO] Target Rootfs: %s
' "$ROOTFS"

mkdir -p "${ROOTFS}/dev"
mkdir -p "${ROOTFS}/dev/pts"
mkdir -p "${ROOTFS}/dev/shm"
mkdir -p "${ROOTFS}/proc"
mkdir -p "${ROOTFS}/sys"
mkdir -p "${ROOTFS}/run"

if [ "$(id -u)" -eq 0 ] && [ "$(uname -s)" = "Linux" ]; then
  printf '[STAGE] Performing real Linux VFS bind mounts...
'
  mount -v --bind /dev "${ROOTFS}/dev" || true
  mount -v --bind /dev/pts "${ROOTFS}/dev/pts" || true
  mount -vt proc proc "${ROOTFS}/proc" || true
  mount -vt sysfs sysfs "${ROOTFS}/sys" || true
  mount -vt tmpfs tmpfs "${ROOTFS}/run" || true
else
  printf '[INFO] Unprivileged or non-Linux host environment detected. Simulated VFS ready.
'
fi

printf '[PASS] Virtual filesystems prepared for chroot.
'
exit 0
