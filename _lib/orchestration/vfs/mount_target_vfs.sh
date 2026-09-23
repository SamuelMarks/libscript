#!/bin/sh
# ## Overview
# Mounts essential Linux virtual kernel filesystems (dev, proc, sys, devpts, shm)
# into a target rootfs directory with re-entrancy and idempotency guards.
#
# ## Usage
# Execute with target rootfs path:
#   ./_lib/orchestration/vfs/mount_target_vfs.sh <target_sysroot>

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
  printf 'Usage: %s <target_sysroot>
' "$THIS_FILE" >&2
  exit 1
fi

[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR"
[ -d "$TARGET_DIR/dev" ] || mkdir -p "$TARGET_DIR/dev"
[ -d "$TARGET_DIR/proc" ] || mkdir -p "$TARGET_DIR/proc"
[ -d "$TARGET_DIR/sys" ] || mkdir -p "$TARGET_DIR/sys"
[ -d "$TARGET_DIR/dev/pts" ] || mkdir -p "$TARGET_DIR/dev/pts"
[ -d "$TARGET_DIR/dev/shm" ] || mkdir -p "$TARGET_DIR/dev/shm"
[ -d "$TARGET_DIR/run" ] || mkdir -p "$TARGET_DIR/run"

is_mounted() {
  _dir="$1"
  if [ -r /proc/mounts ]; then
    grep -qs "[[:space:]]${_dir}[[:space:]]" /proc/mounts
    return $?
  fi
  return 1
}

# Mount /dev if not mounted
if ! is_mounted "$TARGET_DIR/dev"; then
  mount -v --bind /dev "$TARGET_DIR/dev" 2>/dev/null || mount -v -t devtmpfs devtmpfs "$TARGET_DIR/dev"
fi

# Mount /dev/pts if not mounted
if ! is_mounted "$TARGET_DIR/dev/pts"; then
  mount -v -t devpts devpts "$TARGET_DIR/dev/pts" -o gid=5,mode=620 2>/dev/null || mount -v --bind /dev/pts "$TARGET_DIR/dev/pts"
fi

# Mount /dev/shm if not mounted
if ! is_mounted "$TARGET_DIR/dev/shm"; then
  mount -v -t tmpfs tmpfs "$TARGET_DIR/dev/shm" -o mode=1777 2>/dev/null || true
fi

# Mount /proc if not mounted
if ! is_mounted "$TARGET_DIR/proc"; then
  mount -v -t proc proc "$TARGET_DIR/proc"
fi

# Mount /sys if not mounted
if ! is_mounted "$TARGET_DIR/sys"; then
  mount -v -t sysfs sysfs "$TARGET_DIR/sys"
fi

# Mount /run if not mounted
if ! is_mounted "$TARGET_DIR/run"; then
  mount -v -t tmpfs tmpfs "$TARGET_DIR/run" -o mode=0755 2>/dev/null || true
fi

printf '[INFO] Target VFS mount complete for: %s
' "$TARGET_DIR"
exit 0
