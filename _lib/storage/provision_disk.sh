#!/bin/sh
# ## Overview
# Provisions sparse raw disk images and configures partition tables
# (GPT/MBR/FreeBSD) and optional LUKS2 encrypted block layers.
#
# ## Usage
# Execute with target image path and options:
#   ./_lib/storage/provision_disk.sh <target.img> [size_gib] [partition_table] [boot_mode]

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

IMG_PATH="${1:-}"
SIZE_GIB="${2:-10}"
PART_TABLE="${3:-gpt}"
BOOT_MODE="${4:-uefi}"

if [ -z "$IMG_PATH" ]; then
  printf '[ERROR] Target disk image path required.
' >&2
  printf 'Usage: %s <target.img> [size_gib] [partition_table] [boot_mode]
' "$THIS_FILE" >&2
  exit 1
fi

IMG_DIR="${IMG_PATH%/*}"
[ -z "$IMG_DIR" ] || [ -d "$IMG_DIR" ] || mkdir -p "$IMG_DIR"

# 1. Allocate sparse disk image idempotently
if [ ! -f "$IMG_PATH" ]; then
  printf '[INFO] Allocating sparse disk image: %s (%sG)
' "$IMG_PATH" "$SIZE_GIB"
  truncate -s "${SIZE_GIB}G" "$IMG_PATH"
else
  printf '[INFO] Disk image already exists: %s
' "$IMG_PATH"
fi

# 2. Partition disk idempotently if parted/sfdisk available
if command -v parted >/dev/null 2>&1; then
  has_table=$(parted -s "$IMG_PATH" print 2>/dev/null | grep -i "Partition Table:" || true)
  if [ -z "$has_table" ] || printf '%s\n' "$has_table" | grep -qi "unknown"; then
    printf '[INFO] Initializing %s partition table on %s\n' "$PART_TABLE" "$IMG_PATH"
    if [ "$BOOT_MODE" = "freebsd" ] || [ "$PART_TABLE" = "bsd-slice" ]; then
      parted -s "$IMG_PATH" mklabel gpt
      parted -s "$IMG_PATH" mkpart freebsd_boot 1MiB 2MiB
      parted -s "$IMG_PATH" mkpart esp fat32 2MiB 130MiB
      parted -s "$IMG_PATH" set 2 esp on
      parted -s "$IMG_PATH" mkpart freebsd_zfs 130MiB 100%
    elif [ "$BOOT_MODE" = "uefi" ]; then
      parted -s "$IMG_PATH" mklabel gpt
      parted -s "$IMG_PATH" mkpart ESP fat32 1MiB 513MiB
      parted -s "$IMG_PATH" set 1 esp on
      parted -s "$IMG_PATH" mkpart root ext4 513MiB 100%
    elif [ "$BOOT_MODE" = "bios-legacy" ]; then
      parted -s "$IMG_PATH" mklabel gpt
      parted -s "$IMG_PATH" mkpart bios_boot 1MiB 4MiB
      parted -s "$IMG_PATH" set 1 bios_grub on
      parted -s "$IMG_PATH" mkpart root ext4 4MiB 100%
    else
      parted -s "$IMG_PATH" mklabel msdos
      parted -s "$IMG_PATH" mkpart primary ext4 1MiB 100%
      parted -s "$IMG_PATH" set 1 boot on
    fi
  else
    printf '[INFO] Partition table already exists on %s\n' "$IMG_PATH"
  fi
fi

# 3. Optional LUKS2 formatting if requested
LUKS_ENABLED="${5:-0}"
if [ "$LUKS_ENABLED" = "1" ] || [ "$LUKS_ENABLED" = "luks" ] || [ "$LUKS_ENABLED" = "true" ]; then
  if command -v cryptsetup >/dev/null 2>&1 && command -v losetup >/dev/null 2>&1; then
    printf '[INFO] Setting up LUKS2 encryption layer...\n'
    LOOP_DEV=$(losetup -Pf --show "$IMG_PATH" 2>/dev/null || true)
    if [ -n "$LOOP_DEV" ]; then
      TARGET_PART="${LOOP_DEV}p2"
      [ -b "$TARGET_PART" ] || TARGET_PART="${LOOP_DEV}p1"
      if [ -b "$TARGET_PART" ]; then
        if ! cryptsetup isLuks "$TARGET_PART" 2>/dev/null; then
          printf 'libscript-default-luks-passphrase' | cryptsetup luksFormat --type luks2 --pbkdf argon2id --batch-mode "$TARGET_PART" 2>/dev/null || true
        fi
      fi
      losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi
  fi
fi

printf '[INFO] Provisioning disk image completed: %s\n' "$IMG_PATH"
exit 0
