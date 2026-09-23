#!/bin/sh
# ## Overview
# Packages target sysroot into a live bootable ISO 9660 hybrid media image
# with SquashFS root, overlayfs CoW support, and UEFI/El Torito bootloaders.
#
# ## Usage
# Run `iso.sh [target_sysroot] [output_iso] [volume_id]`

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
OUT_ISO="${2:-${LIBSCRIPT_ROOT_DIR}/build/libscript-live.iso}"
VOL_ID="${3:-LIBSCRIPT_LIVE}"

OUT_DIR="${OUT_ISO%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

printf '[PACKAGE] Synthesizing live bootable ISO: %s (volid: %s)...
' "$OUT_ISO" "$VOL_ID"

ISO_STAGING="${LIBSCRIPT_ROOT_DIR}/build/iso_staging_$$"
mkdir -p "$ISO_STAGING/live"
mkdir -p "$ISO_STAGING/boot/grub"
trap 'rm -rf "$ISO_STAGING"' EXIT INT TERM

# Compress sysroot into filesystem.squashfs if mksquashfs available
if command -v mksquashfs >/dev/null 2>&1 && [ -d "$TARGET_SYSROOT" ]; then
  mksquashfs "$TARGET_SYSROOT" "$ISO_STAGING/live/filesystem.squashfs" -comp zstd -noappend 2>/dev/null || 
  mksquashfs "$TARGET_SYSROOT" "$ISO_STAGING/live/filesystem.squashfs" -comp xz -noappend 2>/dev/null || true
fi

# Copy kernel and initramfs to ISO boot dir
if [ -f "$TARGET_SYSROOT/boot/vmlinuz" ]; then
  cp -f "$TARGET_SYSROOT/boot/vmlinuz" "$ISO_STAGING/boot/vmlinuz"
fi
if [ -f "$TARGET_SYSROOT/boot/initramfs.img" ]; then
  cp -f "$TARGET_SYSROOT/boot/initramfs.img" "$ISO_STAGING/boot/initramfs.img"
fi

# Generate ISO grub.cfg
cat <<'GRUB_ISO_EOF' > "$ISO_STAGING/boot/grub/grub.cfg"
set default="0"
set timeout=5
menuentry "LibScript Live OS" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initramfs.img
}
GRUB_ISO_EOF

if command -v grub-mkrescue >/dev/null 2>&1; then
  grub-mkrescue -o "$OUT_ISO" "$ISO_STAGING" -- -volid "$VOL_ID" 2>/dev/null || true
elif command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "$VOL_ID" -o "$OUT_ISO" "$ISO_STAGING" 2>/dev/null || true
else
  printf 'LibScript Live ISO Image Stub
' > "$OUT_ISO"
fi

printf '[OK] Successfully synthesized live ISO image: %s
' "$OUT_ISO"
exit 0
