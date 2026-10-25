#!/bin/sh
# ## Overview
# Idempotently formats unformatted block devices via _lib/storage/format_fs.sh, discovers
# cloud data disks (--auto-data-disk), reconciles /etc/fstab or /etc/vfstab, mounts volumes,
# and normalizes directory ownership.
#
# ## Usage
# ./traits/storage/mount.sh <device_or_uuid|--auto-data-disk> <mount_point> [fstype]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
  printf '%s\n' "Usage: $0 <device_or_uuid|--auto-data-disk> <mount_point> [fstype]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

AUTO_DISCOVER=0
if [ "${1:-}" = "--auto-data-disk" ]; then
  AUTO_DISCOVER=1
  shift
  MOUNT_POINT="${1:-/mnt/data}"
  FSTYPE="${2:-ext4}"
  DEVICE=""
else
  DEVICE="${1:-}"
  MOUNT_POINT="${2:-}"
  FSTYPE="${3:-ext4}"
fi

if [ -z "$MOUNT_POINT" ] || { [ "$AUTO_DISCOVER" -eq 0 ] && [ -z "$DEVICE" ]; }; then
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

# ## normalize_mount_ownership
# Ensures the mounted directory is owned by SERVICE_USER or REMOTE_USER when configured.
normalize_mount_ownership() {
  _nmo_dir="${SYSROOT%/}${MOUNT_POINT}"
  mkdir -p "$_nmo_dir" 2>/dev/null || sudo mkdir -p "$_nmo_dir" 2>/dev/null || true
  _nmo_user="${SERVICE_USER:-${REMOTE_USER:-${ADMIN_USER:-${SUDO_USER:-}}}}"
  if [ -n "$_nmo_user" ] && id "$_nmo_user" >/dev/null 2>&1; then
    _nmo_grp="${SERVICE_GROUP:-${REMOTE_GROUP:-$_nmo_user}}"
    chown -R "${_nmo_user}:${_nmo_grp}" "$_nmo_dir" 2>/dev/null || sudo chown -R "${_nmo_user}:${_nmo_grp}" "$_nmo_dir" 2>/dev/null || true
  fi
}

# ## is_already_mounted
# Checks whether MOUNT_POINT is already an active mountpoint.
is_already_mounted() {
  if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null; then
    return 0
  fi
  if [ -f /proc/mounts ] && grep -q " ${SYSROOT%/}${MOUNT_POINT} " /proc/mounts 2>/dev/null; then
    return 0
  fi
  if command -v mount >/dev/null 2>&1 && mount | grep -q " on ${SYSROOT%/}${MOUNT_POINT} "; then
    return 0
  fi
  return 1
}

if [ "$AUTO_DISCOVER" -eq 1 ]; then
  if [ "$SYSROOT" = "/" ] && is_already_mounted; then
    normalize_mount_ownership
    printf '[INFO] %s is already mounted; ownership normalized.\n' "$MOUNT_POINT"
    exit 0
  fi
  if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/storage/disk_discovery.sh" ]; then
    DEVICE=$("${LIBSCRIPT_ROOT_DIR}/_lib/storage/disk_discovery.sh" --auto-data-disk 2>/dev/null || true)
  fi
  if [ -z "$DEVICE" ]; then
    normalize_mount_ownership
    printf '[INFO] No unmounted physical data disk detected; prepared directory %s.\n' "$MOUNT_POINT"
    exit 0
  fi
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
  if command -v fstyp >/dev/null 2>&1 && fstyp "$dev_target" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# ## reconcile_fstab_entry
# Writes persistent fstab or vfstab entry inside libscript-trait-storage markers idempotently.
reconcile_fstab_entry() {
  mkdir -p "${SYSROOT%/}/etc" 2>/dev/null || sudo mkdir -p "${SYSROOT%/}/etc" 2>/dev/null || true
  mkdir -p "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null || sudo mkdir -p "${SYSROOT%/}${MOUNT_POINT}" 2>/dev/null || true
  touch "$FSTAB_FILE" 2>/dev/null || sudo touch "$FSTAB_FILE" 2>/dev/null || true
  marker_id="libscript-trait-storage:${MOUNT_POINT}"
  if ! grep -q "# BEGIN ${marker_id}" "$FSTAB_FILE" 2>/dev/null; then
    if [ -w "$FSTAB_FILE" ]; then
      {
        printf '# BEGIN %s\n' "$marker_id"
        printf '%s %s %s defaults,nofail 0 2\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
        printf '# END %s\n' "$marker_id"
      } >> "$FSTAB_FILE"
    else
      sudo sh -c "printf '# BEGIN %s\n%s %s %s defaults,nofail 0 2\n# END %s\n' '$marker_id' '$DEVICE' '$MOUNT_POINT' '$FSTYPE' '$marker_id' >> '$FSTAB_FILE'" 2>/dev/null || true
    fi
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
  if ! is_already_mounted; then
    mount -t "$FSTYPE" "$DEVICE" "$MOUNT_POINT" 2>/dev/null || sudo mount -t "$FSTYPE" "$DEVICE" "$MOUNT_POINT" 2>/dev/null || true
  fi
fi
normalize_mount_ownership
printf '[INFO] Storage trait applied for %s -> %s (%s).\n' "$DEVICE" "$MOUNT_POINT" "$FSTYPE"
