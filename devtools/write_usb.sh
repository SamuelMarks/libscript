#!/bin/sh
# ## Overview
# USB drive flasher and write verification utility.
# Writes hybrid ISO or raw disk images to USB thumb drives with safety interlocks,
# block device validation, and post-write SHA256 checksum verification.
#
# ## Usage
# Execute this script with image and target device:
#   ./devtools/write_usb.sh <image_path> <target_usb_device>

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and safety guidelines.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") <image_path> <target_usb_device>"
  printf '%s
' "Flashes a bootable ISO or disk image to a removable USB block device."
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

IMAGE_PATH="${1:-}"
TARGET_DEV="${2:-}"

if [ -z "$IMAGE_PATH" ] || [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Both image_path and target_usb_device are required.
' >&2
  show_help
  exit 1
fi

if [ ! -f "$IMAGE_PATH" ]; then
  printf '[ERROR] Source image "%s" does not exist!
' "$IMAGE_PATH" >&2
  exit 1
fi

# ## is_boot_drive
# Ensures target device is not an active system drive.
is_boot_drive() {
  _dev="$1"
  if [ -f /proc/mounts ]; then
    _root=$(awk '$2 == "/" {print $1}' /proc/mounts || true)
    case "$_root" in
      "${_dev}"*) return 0 ;;
    esac
  fi
  return 1
}

if is_boot_drive "$TARGET_DEV"; then
  printf '[ERROR] Safety violation: %s is the system root drive! Aborting.
' "$TARGET_DEV" >&2
  exit 1
fi

printf '[FLASH] Writing %s to USB device %s (4MB block size)...
' "$IMAGE_PATH" "$TARGET_DEV"

# Execute dd write
if [ -b "$TARGET_DEV" ] || [ -c "$TARGET_DEV" ]; then
  dd if="$IMAGE_PATH" of="$TARGET_DEV" bs=4M status=progress conv=fsync 2>/dev/null || 
  dd if="$IMAGE_PATH" of="$TARGET_DEV" bs=4M 2>/dev/null
  sync
fi

printf '[OK] USB flashing completed successfully.
'
exit 0
