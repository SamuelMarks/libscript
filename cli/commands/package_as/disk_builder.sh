#!/bin/sh
# ## Overview
# Assembles a Linux root filesystem into a bootable partitioned disk image (.raw)
# with EFI System Partition (vfat), populated Root partition (ext4/btrfs), UUID fstab, and bootloader.
# ## Usage
# ./cli/commands/package_as/disk_builder.sh [--strict | --allow-stub] [target_rootfs] [output.raw] [size_gib]

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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [target_rootfs] [output.raw] [size_gib] [bootloader]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --strict) STRICT_BUILD=1; shift ;;
    --allow-stub) ALLOW_STUB=1; shift ;;
    *) break ;;
  esac
done

ROOTFS="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/lfs/rootfs}}"
OUT_RAW="${2:-${LIBSCRIPT_ROOT_DIR}/build/lfs/lfs-system.raw}"
SIZE_GIB="${3:-4}"
BOOTLOADER="${4:-grub2-efi}"
STAMPS_DIR="${LIBSCRIPT_ROOT_DIR}/build/stamps"

mkdir -p "$STAMPS_DIR" "$(dirname "$OUT_RAW")" "$ROOTFS/etc"
STAMP_DISK="${STAMPS_DIR}/.stamp.lfs_disk_$(basename "$OUT_RAW")"

if [ -f "$STAMP_DISK" ] && [ -s "$OUT_RAW" ]; then
  if grep -q '^mode=stub$' "$STAMP_DISK" 2>/dev/null && [ "$STRICT_BUILD" = "1" ]; then
    rm -f "$STAMP_DISK"
  else
    printf '[SKIP]  LFS disk image already built (%s)\n' "$STAMP_DISK"
    exit 0
  fi
fi

LOOP_DEV=''
MNT_ROOT="${LIBSCRIPT_ROOT_DIR}/build/mnt_disk_$$"

# ## cleanup_disk_builder
# Unmounts temporary partitions and detaches loopback devices on exit or interrupt.
# shellcheck disable=SC2329
cleanup_disk_builder() {
  if [ -d "$MNT_ROOT" ]; then
    umount "${MNT_ROOT}/boot/efi" >/dev/null 2>&1 || true
    umount "$MNT_ROOT" >/dev/null 2>&1 || true
    rmdir "$MNT_ROOT" >/dev/null 2>&1 || true
  fi
  if [ -n "$LOOP_DEV" ] && command -v losetup >/dev/null 2>&1; then
    losetup -d "$LOOP_DEV" >/dev/null 2>&1 || true
  fi
}
trap cleanup_disk_builder EXIT INT TERM HUP

printf '=== LibScript Partitioned Disk Image Synthesizer ===\n'
if command -v truncate >/dev/null 2>&1; then
  truncate -s "${SIZE_GIB}G" "$OUT_RAW"
else
  dd if=/dev/zero of="$OUT_RAW" bs=1M count=0 seek="$((SIZE_GIB * 1024))" 2>/dev/null
fi

if command -v sgdisk >/dev/null 2>&1; then
  sgdisk --clear --new=1:2048:+512M --typecode=1:ef00 --change-name=1:"EFI System" --new=2:0:0 --typecode=2:8300 --change-name=2:"Linux Root" "$OUT_RAW" >/dev/null 2>&1 || true
elif command -v parted >/dev/null 2>&1; then
  parted -s "$OUT_RAW" mklabel gpt mkpart ESP fat32 1MiB 513MiB set 1 esp on mkpart root ext4 513MiB 100% 2>/dev/null || true
fi

if [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/bootloaders/setup.sh" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/bootloaders/setup.sh" compile "$ROOTFS" "$BOOTLOADER" "uefi" >/dev/null 2>&1 || true
fi

STAMP_MODE='stub'
if [ "$(id -u 2>/dev/null || printf '1000')" -eq 0 ] && command -v losetup >/dev/null 2>&1; then
  LOOP_DEV=$(losetup --find --partscan --show "$OUT_RAW" 2>/dev/null || true)
  if [ -n "$LOOP_DEV" ] && [ -b "${LOOP_DEV}p2" ]; then
    command -v mkfs.vfat >/dev/null 2>&1 && mkfs.vfat -F 32 -n EFI "${LOOP_DEV}p1" >/dev/null 2>&1 || true
    if command -v mkfs.ext4 >/dev/null 2>&1; then
      mkfs.ext4 -F -L rootfs -d "$ROOTFS" "${LOOP_DEV}p2" >/dev/null 2>&1 || mkfs.ext4 -F -L rootfs "${LOOP_DEV}p2" >/dev/null 2>&1 || true
    fi
    mkdir -p "$MNT_ROOT"
    if mount "${LOOP_DEV}p2" "$MNT_ROOT" 2>/dev/null; then
      cp -a "${ROOTFS}/." "$MNT_ROOT/" 2>/dev/null || true
      mkdir -p "${MNT_ROOT}/boot/efi"
      if [ -b "${LOOP_DEV}p1" ] && mount "${LOOP_DEV}p1" "${MNT_ROOT}/boot/efi" 2>/dev/null; then
        mkdir -p "${MNT_ROOT}/boot/efi/EFI/BOOT"
        if [ -f "${ROOTFS}/boot/efi/EFI/BOOT/BOOTX64.EFI" ]; then
          cp -f "${ROOTFS}/boot/efi/EFI/BOOT/BOOTX64.EFI" "${MNT_ROOT}/boot/efi/EFI/BOOT/BOOTX64.EFI"
        fi
        umount "${MNT_ROOT}/boot/efi" 2>/dev/null || true
      fi
      _root_uuid=$(blkid -s UUID -o value "${LOOP_DEV}p2" 2>/dev/null || printf '')
      _esp_uuid=$(blkid -s UUID -o value "${LOOP_DEV}p1" 2>/dev/null || printf '')
      if [ -n "$_root_uuid" ]; then
        printf 'UUID=%s / ext4 defaults,noatime 0 1\n' "$_root_uuid" > "${MNT_ROOT}/etc/fstab"
        [ -n "$_esp_uuid" ] && printf 'UUID=%s /boot/efi vfat umask=0077 0 2\n' "$_esp_uuid" >> "${MNT_ROOT}/etc/fstab"
      fi
      sync
      umount "$MNT_ROOT" 2>/dev/null || true
      STAMP_MODE='native'
    fi
  fi
elif command -v mkfs.ext4 >/dev/null 2>&1 && [ ! -f "$OUT_RAW" ]; then
  mkfs.ext4 -F -d "$ROOTFS" "$OUT_RAW" "${SIZE_GIB}G" >/dev/null 2>&1 && STAMP_MODE='native' || true
fi

if [ "$STAMP_MODE" = "stub" ] && [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR] Strict Linux disk synthesis requires root loopback privileges (losetup + mkfs.vfat + mkfs.ext4).\n' >&2
  rm -f "$OUT_RAW" "$STAMP_DISK"
  exit 1
fi

printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_DISK}.tmp"
mv "${STAMP_DISK}.tmp" "$STAMP_DISK"
printf '[DONE]  LFS disk image assembled (%s): %s\n' "$STAMP_MODE" "$OUT_RAW"
exit 0
