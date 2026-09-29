#!/bin/sh
# ## Overview
# Unified filesystem formatter and OpenZFS root pool initialization engine.
# Prepares EFI System Partitions (FAT32), Linux root filesystems (ext4/xfs/btrfs),
# FreeBSD UFS2 partitions, and canonical OpenZFS root pools with structured datasets.
#
# ## Usage
# Execute this script to format a block partition or initialize a ZFS pool:
#   ./_lib/storage/format.sh <device_or_slice> [fs_type] [pool_name]

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

# ## show_help
# Displays usage instructions and supported filesystem options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <device_or_slice> [fs_type] [pool_name]"
  printf '%s
' "Formats block partitions or creates structured ZFS root pools."
  printf '
'
  printf '%s
' "Filesystem Types:"
  printf '%s
' "  fat32     - EFI System Partition (FAT32)"
  printf '%s
' "  ext4      - Linux Fourth Extended Filesystem (default)"
  printf '%s
' "  xfs       - Linux XFS high-performance filesystem"
  printf '%s
' "  btrfs     - Linux Btrfs copy-on-write filesystem"
  printf '%s
' "  ufs2      - FreeBSD Unix File System 2 with soft-updates"
  printf '%s
' "  zfs       - OpenZFS root pool with canonical dataset hierarchy"
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_DEV="${1:-}"
FS_TYPE="${2:-ext4}"
POOL_NAME="${3:-rpool}"

if [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Target device or partition path is required.
' >&2
  show_help
  exit 1
fi

# ## detect_os
# Identifies the active operating system kernel family.
detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# ## probe_existing_fs
# Determines if the target partition is already formatted.
probe_existing_fs() {
  _dev="$1"
  if command -v blkid >/dev/null 2>&1; then
    blkid -s TYPE -o value "$_dev" 2>/dev/null || true
  elif command -v fstyp >/dev/null 2>&1; then
    fstyp "$_dev" 2>/dev/null || true
  fi
}

# ## format_fat32
# Formats partition as FAT32 for EFI ESP.
format_fat32() {
  _dev="$1"
  printf '[INFO] Formatting %s as FAT32 EFI System Partition...
' "$_dev"
  if command -v mkfs.vfat >/dev/null 2>&1; then
    mkfs.vfat -F 32 -n "EFI" "$_dev"
  elif command -v newfs_msdos >/dev/null 2>&1; then
    newfs_msdos -F 32 -L "EFI" "$_dev"
  elif command -v mkfs >/dev/null 2>&1; then
    mkfs -F pcfs -o fat=32 "$_dev"
  fi
}

# ## format_ext4
# Formats partition as Linux ext4.
format_ext4() {
  _dev="$1"
  printf '[INFO] Formatting %s as ext4...
' "$_dev"
  mkfs.ext4 -F -O 64bit -L "rootfs" "$_dev"
}

# ## format_xfs
# Formats partition as Linux XFS.
format_xfs() {
  _dev="$1"
  printf '[INFO] Formatting %s as xfs...
' "$_dev"
  mkfs.xfs -f -L "rootfs" "$_dev"
}

# ## format_btrfs
# Formats partition as Linux Btrfs.
format_btrfs() {
  _dev="$1"
  printf '[INFO] Formatting %s as btrfs...
' "$_dev"
  mkfs.btrfs -f -L "rootfs" "$_dev"
}

# ## format_ufs2
# Formats partition as FreeBSD UFS2 with soft updates.
format_ufs2() {
  _dev="$1"
  printf '[INFO] Formatting %s as FreeBSD UFS2...
' "$_dev"
  newfs -U -j -t -L "rootfs" "$_dev"
}

# ## init_zfs_pool
# Initializes canonical OpenZFS root pool and builds structured dataset hierarchy.
init_zfs_pool() {
  _dev="$1"
  _pool="$2"
  _os=$(detect_os)

  printf '[INFO] Initializing OpenZFS root pool %s on %s (%s)...
' "$_pool" "$_dev" "$_os"

  # Idempotency: check if pool already exists
  if command -v zpool >/dev/null 2>&1; then
    if zpool list "$_pool" >/dev/null 2>&1; then
      printf '[INFO] ZFS pool %s already active. Skipping creation.
' "$_pool"
      return 0
    fi
  fi

  case "$_os" in
    freebsd*)
      zpool create -f -o ashift=12 -O compress=lz4 -O atime=off -m none -R /mnt/target "$_pool" "$_dev"
      zfs create -o mountpoint=none "${_pool}/ROOT"
      zfs create -o mountpoint=/ "${_pool}/ROOT/default"
      zfs create -o mountpoint=/var "${_pool}/var"
      zfs create -o mountpoint=/tmp -o exec=on -o setuid=off "${_pool}/tmp"
      zfs create -o mountpoint=/usr "${_pool}/usr"
      zfs create -o mountpoint=/home "${_pool}/home"
      zpool set bootfs="${_pool}/ROOT/default" "$_pool"
      ;;
    sunos*)
      zpool create -f -o ashift=12 -B -R /mnt/target "$_pool" "$_dev"
      zfs create -o mountpoint=none "${_pool}/ROOT"
      zfs create -o mountpoint=/ "${_pool}/ROOT/illumos"
      zfs create -o mountpoint=/var "${_pool}/var"
      zpool set bootfs="${_pool}/ROOT/illumos" "$_pool"
      ;;
    *)
      # Linux OpenZFS
      zpool create -f -o ashift=12 -O compression=lz4 -O acltype=posixacl -O xattr=sa -O relatime=on -m none -R /mnt/target "$_pool" "$_dev"
      zfs create -o mountpoint=none "${_pool}/ROOT"
      zfs create -o mountpoint=/ "${_pool}/ROOT/linux"
      zfs create -o mountpoint=/var "${_pool}/var"
      zfs create -o mountpoint=/home "${_pool}/home"
      zpool set bootfs="${_pool}/ROOT/linux" "$_pool"
      ;;
  esac
}

# Check existing filesystem for idempotency
current_fs=$(probe_existing_fs "$TARGET_DEV" || true)
if [ -n "$current_fs" ] && [ "$FS_TYPE" != "zfs" ]; then
  case "$current_fs" in
    vfat|fat32|ext4|xfs|btrfs|ufs|ufs2)
      printf '[INFO] Device %s already formatted with %s. Preserving.
' "$TARGET_DEV" "$current_fs"
      exit 0
      ;;
  esac
fi

case "$FS_TYPE" in
  fat32|vfat|esp)
    format_fat32 "$TARGET_DEV"
    ;;
  ext4)
    format_ext4 "$TARGET_DEV"
    ;;
  xfs)
    format_xfs "$TARGET_DEV"
    ;;
  btrfs)
    format_btrfs "$TARGET_DEV"
    ;;
  ufs|ufs2)
    format_ufs2 "$TARGET_DEV"
    ;;
  zfs)
    init_zfs_pool "$TARGET_DEV" "$POOL_NAME"
    ;;
  *)
    printf '[ERROR] Unknown filesystem type: %s
' "$FS_TYPE" >&2
    exit 1
    ;;
esac

printf '[OK] Formatting of %s as %s completed successfully.
' "$TARGET_DEV" "$FS_TYPE"
exit 0
