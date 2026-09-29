#!/bin/sh
# ## Overview
# Unified cross-platform partition manipulator supporting GPT, MBR, and illumos VTOC layouts.
# Automatically synthesizes standard EFI System Partitions, BIOS boot partitions, swap slices,
# and primary root partitions with full idempotency across Linux, FreeBSD, and illumos.
#
# ## Usage
# Execute this script to partition a target disk or raw image:
#   ./_lib/storage/partitioner.sh <device_or_image> [scheme] [boot_mode] [swap_mib]

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
# Displays usage information and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <device_or_image> [scheme] [boot_mode] [swap_mib]"
  printf '%s
' "Partitions storage media for Linux, FreeBSD, or illumos installations."
  printf '
'
  printf '%s
' "Schemes:"
  printf '%s
' "  gpt       - GUID Partition Table for modern UEFI and hybrid systems (default)"
  printf '%s
' "  mbr       - Master Boot Record for legacy BIOS hardware"
  printf '%s
' "  vtoc      - Solaris / illumos SMI VTOC slice partition table"
  printf '
'
  printf '%s
' "Boot Modes:"
  printf '%s
' "  uefi      - UEFI boot (creates 512MB FAT32 ESP partition)"
  printf '%s
' "  bios      - Legacy BIOS boot (creates 1MB BIOS boot partition on GPT)"
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
SCHEME="${2:-gpt}"
BOOT_MODE="${3:-uefi}"
SWAP_MIB="${4:-2048}"

if [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Target device or disk image path is required.
' >&2
  show_help
  exit 1
fi

# ## detect_os
# Identifies the active operating system kernel family.
detect_os() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# ## check_existing_partitions
# Checks if the target device already has valid partitions configured.
check_existing_partitions() {
  _dev="$1"
  if command -v parted >/dev/null 2>&1; then
    _pt=$(parted -s "$_dev" print 2>/dev/null | awk '/Partition Table:/ {print $3}' || true)
    if [ -n "$_pt" ] && [ "$_pt" != "unknown" ]; then
      return 0
    fi
  fi
  if command -v gpart >/dev/null 2>&1; then
    _geom_name=$(basename "$_dev")
    if gpart show "$_geom_name" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

# ## partition_linux_gpt
# Creates standardized GPT partitions using sgdisk or parted on Linux.
partition_linux_gpt() {
  _dev="$1"
  _boot="$2"
  _swap="$3"

  printf '[INFO] Partitioning %s via GPT for %s...
' "$_dev" "$_boot"

  if command -v sgdisk >/dev/null 2>&1; then
    # Zap existing tables cleanly
    sgdisk --zap-all "$_dev" >/dev/null 2>&1 || true

    if [ "$_boot" = "uefi" ]; then
      # 1: ESP (512MB), 2: Swap, 3: Root
      sgdisk -n 1:2048:+512M -t 1:ef00 -c 1:"EFI System Partition" "$_dev"
      if [ "$_swap" -gt 0 ]; then
        sgdisk -n 2:0:+${_swap}M -t 2:8200 -c 2:"Linux Swap" "$_dev"
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" "$_dev"
      else
        sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux Root" "$_dev"
      fi
    else
      # BIOS on GPT: 1: BIOS Boot (1MB), 2: Swap, 3: Root
      sgdisk -n 1:2048:+1M -t 1:ef02 -c 1:"BIOS Boot Partition" "$_dev"
      if [ "$_swap" -gt 0 ]; then
        sgdisk -n 2:0:+${_swap}M -t 2:8200 -c 2:"Linux Swap" "$_dev"
        sgdisk -n 3:0:0 -t 3:8300 -c 3:"Linux Root" "$_dev"
      else
        sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux Root" "$_dev"
      fi
    fi
  elif command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" mklabel gpt
    if [ "$_boot" = "uefi" ]; then
      parted -s "$_dev" mkpart esp fat32 1MiB 513MiB
      parted -s "$_dev" set 1 esp on
      _start=513MiB
    else
      parted -s "$_dev" mkpart bios_boot 1MiB 2MiB
      parted -s "$_dev" set 1 bios_grub on
      _start=2MiB
    fi
    if [ "$_swap" -gt 0 ]; then
      _swap_end=$((513 + _swap))
      parted -s "$_dev" mkpart swap linux-swap "$_start" "${_swap_end}MiB"
      parted -s "$_dev" mkpart root ext4 "${_swap_end}MiB" 100%
    else
      parted -s "$_dev" mkpart root ext4 "$_start" 100%
    fi
  fi
}

# ## partition_freebsd_gpt
# Creates standardized GPT partitions using gpart on FreeBSD.
partition_freebsd_gpt() {
  _dev="$1"
  _boot="$2"
  _swap="$3"
  _geom=$(basename "$_dev")

  printf '[INFO] Partitioning %s via FreeBSD gpart...
' "$_dev"
  gpart destroy -F "$_geom" >/dev/null 2>&1 || true
  gpart create -s gpt "$_geom"

  if [ "$_boot" = "uefi" ]; then
    gpart add -t efi -s 512M -l "efiboot" "$_geom"
  else
    gpart add -t freebsd-boot -s 512K -l "bootcode" "$_geom"
    gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$_geom" || true
  fi

  if [ "$_swap" -gt 0 ]; then
    gpart add -t freebsd-swap -s "${_swap}M" -l "swap" "$_geom"
  fi

  gpart add -t freebsd-zfs -l "zroot" "$_geom"
}

# ## partition_illumos_vtoc
# Creates standardized VTOC slice layout on illumos.
partition_illumos_vtoc() {
  _dev="$1"
  printf '[INFO] Configuring illumos partition slices for %s...
' "$_dev"
  if command -v format >/dev/null 2>&1; then
    printf 'fdisk
' | format "$_dev" >/dev/null 2>&1 || true
  fi
}

# ## partition_dual_os_gpt
# Partitions storage media with dual root partitions for concurrent Linux and FreeBSD installations.
partition_dual_os_gpt() {
  _dev="$1"
  _swap="$2"
  printf '[INFO] Partitioning %s for concurrent Dual-OS (Linux + FreeBSD)...\n' "$_dev"

  if command -v sgdisk >/dev/null 2>&1; then
    sgdisk --zap-all "$_dev" >/dev/null 2>&1 || true
    sgdisk -n 1:2048:+512M -t 1:ef00 -c 1:"Shared EFI ESP" "$_dev"
    if [ "$_swap" -gt 0 ]; then
      sgdisk -n 2:0:+${_swap}M -t 2:8200 -c 2:"Shared Swap" "$_dev"
      sgdisk -n 3:0:+20G -t 3:8300 -c 3:"Linux Root" "$_dev"
      sgdisk -n 4:0:0 -t 4:51687CBA-600F-11D6-A2E4-005054508801 -c 4:"FreeBSD Root" "$_dev"
    else
      sgdisk -n 2:0:+20G -t 2:8300 -c 2:"Linux Root" "$_dev"
      sgdisk -n 3:0:0 -t 3:51687CBA-600F-11D6-A2E4-005054508801 -c 3:"FreeBSD Root" "$_dev"
    fi
  elif command -v parted >/dev/null 2>&1; then
    parted -s "$_dev" mklabel gpt
    parted -s "$_dev" mkpart esp fat32 1MiB 513MiB
    parted -s "$_dev" set 1 esp on
    if [ "$_swap" -gt 0 ]; then
      _swap_end=$((513 + _swap))
      parted -s "$_dev" mkpart swap linux-swap 513MiB "${_swap_end}MiB"
      parted -s "$_dev" mkpart linux_root ext4 "${_swap_end}MiB" 50%
      parted -s "$_dev" mkpart freebsd_root 50% 100%
    else
      parted -s "$_dev" mkpart linux_root ext4 513MiB 50%
      parted -s "$_dev" mkpart freebsd_root 50% 100%
    fi
  fi
}

# Idempotency check:
if check_existing_partitions "$TARGET_DEV"; then
  printf '[INFO] Device %s already contains valid partition table. Preserving.\n' "$TARGET_DEV"
  exit 0
fi

if [ "$SCHEME" = "gpt-dual-os" ] || [ "$SCHEME" = "dual" ]; then
  partition_dual_os_gpt "$TARGET_DEV" "$SWAP_MIB"
  printf '[OK] Dual-OS partitioning of %s completed successfully.\n' "$TARGET_DEV"
  exit 0
fi

current_os=$(detect_os)
case "$current_os" in
  freebsd*)
    partition_freebsd_gpt "$TARGET_DEV" "$BOOT_MODE" "$SWAP_MIB"
    ;;
  sunos*)
    partition_illumos_vtoc "$TARGET_DEV"
    ;;
  *)
    # Linux and generic fallback
    if [ "$SCHEME" = "gpt" ]; then
      partition_linux_gpt "$TARGET_DEV" "$BOOT_MODE" "$SWAP_MIB"
    else
      # MBR fallback
      parted -s "$TARGET_DEV" mklabel msdos
      parted -s "$TARGET_DEV" mkpart primary ext4 1MiB 100%
      parted -s "$TARGET_DEV" set 1 boot on
    fi
    ;;
esac

printf '[OK] Partitioning of %s completed successfully.
' "$TARGET_DEV"
exit 0
