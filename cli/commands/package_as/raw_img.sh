#!/bin/sh
# ## Overview
# Packages a target sysroot into a partitioned, bootable raw disk image (.img)
# delegating GPT/ESP/rootfs population and fstab synthesis to disk_builder.sh.
# ## Usage
# ./cli/commands/package_as/raw_img.sh [--strict | --allow-stub] [target_sysroot] [output_image] [size_gib] [boot_mode]

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

EXTRA_FLAGS=''
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [target_sysroot] [output_image] [size_gib] [boot_mode]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --strict) EXTRA_FLAGS='--strict'; shift ;;
    --allow-stub) EXTRA_FLAGS='--allow-stub'; shift ;;
    *) break ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/raw/disk.img}"
SIZE_GIB="${3:-4}"
BOOT_MODE="${4:-uefi}"
BOOTLOADER='grub2-efi'
if [ "$BOOT_MODE" = "bios" ] || [ "$BOOT_MODE" = "bios-legacy" ]; then
  BOOTLOADER='grub2-bios'
fi

if [ -n "$EXTRA_FLAGS" ]; then
  STACK='' "${SCRIPT_DIR}/disk_builder.sh" "$EXTRA_FLAGS" "$TARGET_SYSROOT" "$OUT_IMG" "$SIZE_GIB" "$BOOTLOADER"
else
  STACK='' "${SCRIPT_DIR}/disk_builder.sh" "$TARGET_SYSROOT" "$OUT_IMG" "$SIZE_GIB" "$BOOTLOADER"
fi
printf '[OK] Successfully synthesized raw disk image: %s\n' "$OUT_IMG"
exit 0
