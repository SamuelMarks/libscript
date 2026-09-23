#!/bin/sh
# ## Overview
# Packages a target sysroot into a partitioned, bootable raw disk image (.img)
# suitable for direct block writing (dd) to physical disks or hypervisor attachments.
#
# ## Usage
# Run `raw_img.sh [target_sysroot] [output_image] [size_gib] [boot_mode]`

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

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/disk.img}"
SIZE_GIB="${3:-10}"
BOOT_MODE="${4:-uefi}"

OUT_DIR="${OUT_IMG%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

printf '[PACKAGE] Synthesizing raw disk image: %s (%sG, %s)...
' "$OUT_IMG" "$SIZE_GIB" "$BOOT_MODE"

# 1. Provision raw disk image
"${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$OUT_IMG" "$SIZE_GIB" "gpt" "$BOOT_MODE"

# 2. Bootloader and rootfs synchronization
if [ -d "$TARGET_SYSROOT" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/bootloaders/setup.sh" compile "$TARGET_SYSROOT" grub2-efi "$BOOT_MODE"
fi

printf '[OK] Successfully synthesized raw disk image: %s
' "$OUT_IMG"
exit 0
