#!/bin/sh
# ## Overview
# Idempotently formats unformatted block devices via _lib/storage/format_fs.sh and reconciles /etc/fstab or /etc/vfstab.
#
# ## Usage
# ./traits/storage/mount.sh <device_or_uuid> <mount_point> [fstype]

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
export LIBSCRIPT_ROOT_DIR

# ## print_usage
# Prints usage instructions for traits/storage/mount.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <device_or_uuid> <mount_point> [fstype]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

DEVICE="${1:-}"
MOUNT_POINT="${2:-}"
FSTYPE="${3:-ext4}"

if [ -z "$DEVICE" ] || [ -z "$MOUNT_POINT" ]; then
  print_usage >&2
  exit 1
fi

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-/}"
OS_NAME="$(uname -s 2>/dev/null || printf 'Linux')"
if [ "$OS_NAME" = "SunOS" ]; then
  FSTAB_FILE="${SYSROOT%/}/etc/vfstab"
else
  FSTAB_FILE="${SYSROOT%/}/etc/fstab"
fi

# ## check_existing_signature
# Checks whether the block device already has a valid filesystem signature to prevent destructive formatting.
check_existing_signature() {
  dev_target="$1"
  if [ -f "$dev_target" ] && grep -q "LIBSCRIPT_FS_SIGNATURE" "$dev_target" 2>/dev/null; then
    return 0
  fi
  if command -v blkid >/dev/null 2>&1 && blkid "$dev_target" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ## reconcile_fstab_entry
# Writes persistent fstab or vfstab entry inside libscript-trait-storage markers idempotently.
reconcile_fstab_entry() {
  mkdir -p "${SYSROOT%/}/etc"
  mkdir -p "${SYSROOT%/}${MOUNT_POINT}"
  touch "$FSTAB_FILE"
  marker_id="libscript-trait-storage:${MOUNT_POINT}"
  if ! grep -q "# BEGIN ${marker_id}" "$FSTAB_FILE" 2>/dev/null; then
    {
      printf '# BEGIN %s\n' "$marker_id"
      printf '%s %s %s defaults,nofail 0 2\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
      printf '# END %s\n' "$marker_id"
    } >> "$FSTAB_FILE"
  fi
}

if check_existing_signature "$DEVICE"; then
  printf '[INFO] Existing filesystem signature detected on %s; skipping format_fs.\n' "$DEVICE"
elif [ "$SYSROOT" = "/" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -b "$DEVICE" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/format_fs.sh" "$DEVICE" "$FSTYPE"
elif [ -f "$DEVICE" ]; then
  printf 'LIBSCRIPT_FS_SIGNATURE=%s\n' "$FSTYPE" > "$DEVICE"
fi

reconcile_fstab_entry

if [ "$SYSROOT" = "/" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ -b "$DEVICE" ]; then
  if ! mount | grep -q " on ${MOUNT_POINT} "; then
    mount -t "$FSTYPE" "$DEVICE" "$MOUNT_POINT" 2>/dev/null || true
  fi
fi
printf '[INFO] Storage trait applied for %s -> %s (%s).\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
