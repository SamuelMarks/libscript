#!/bin/sh
# ## Overview
# Safely unmounts virtual kernel filesystems (run, sys, proc, shm, pts, dev)
# from a target sysroot in reverse order.
#
# ## Usage
# Execute with target rootfs path:
#   ./_lib/orchestration/vfs/umount_target_vfs.sh <target_sysroot>

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

TARGET_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-}}"

if [ -z "$TARGET_DIR" ]; then
  printf '[ERROR] Target sysroot directory must be provided.
' >&2
  printf 'Usage: %s <target_sysroot>\n' "$THIS_FILE" >&2
  exit 1
fi

# ## is_mounted
# Checks if a directory is mounted according to /proc/mounts.
is_mounted() {
  _dir="$1"
  if [ -r /proc/mounts ]; then
    grep -qs "[[:space:]]${_dir}[[:space:]]" /proc/mounts
    return $?
  fi
  return 1
}

# ## safe_umount
# Safely unmounts a target mount point if currently mounted.
safe_umount() {
  _mount_point="$1"
  if is_mounted "$_mount_point"; then
    umount "$_mount_point" 2>/dev/null || umount -l "$_mount_point" 2>/dev/null || true
  fi
}

# Unmount in reverse order of mounting
safe_umount "$TARGET_DIR/run"
safe_umount "$TARGET_DIR/sys"
safe_umount "$TARGET_DIR/proc"
safe_umount "$TARGET_DIR/dev/shm"
safe_umount "$TARGET_DIR/dev/pts"
safe_umount "$TARGET_DIR/dev"

printf '[INFO] Target VFS unmount complete for: %s
' "$TARGET_DIR"
exit 0
