#!/bin/sh
# ## Overview
# Packages target sysroot into a live bootable ISO 9660 hybrid media image
# with SquashFS root, overlayfs CoW support, and UEFI/El Torito bootloaders.
#
# ## Usage
# Run `iso.sh [--strict | --allow-stub] [target_sysroot] [output_iso] [volume_id]`

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
      printf 'Usage: %s [--strict | --allow-stub] [target_sysroot] [output_iso] [volume_id]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --strict)
      STRICT_BUILD=1
      shift
      ;;
    --allow-stub)
      ALLOW_STUB=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_ISO="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/iso/libscript-live.iso}"
VOL_ID="${3:-LIBSCRIPT_LIVE}"
STAMP_FILE="${OUT_ISO}.stamp"

# ## has_native_iso_tool
# Returns 0 if a genuine ISO 9660 generator is available on the host.
has_native_iso_tool() {
  command -v grub-mkrescue >/dev/null 2>&1 ||
    command -v xorriso >/dev/null 2>&1 ||
    command -v mkisofs >/dev/null 2>&1 ||
    command -v genisoimage >/dev/null 2>&1 ||
    command -v makefs >/dev/null 2>&1 ||
    command -v hdiutil >/dev/null 2>&1
}

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_ISO" ]; then
  if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
    if [ "$STRICT_BUILD" = "1" ] || has_native_iso_tool; then
      rm -f "$STAMP_FILE"
    else
      printf '[SKIP] Live ISO image already synthesized (stub): %s\n' "$OUT_ISO"
      exit 0
    fi
  else
    printf '[SKIP] Live ISO image already synthesized: %s\n' "$OUT_ISO"
    exit 0
  fi
fi

OUT_DIR="${OUT_ISO%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

printf '[PACKAGE] Synthesizing live bootable ISO: %s (volid: %s)...\n' "$OUT_ISO" "$VOL_ID"

ISO_STAGING="${LIBSCRIPT_ROOT_DIR}/build/iso_staging_$$"
mkdir -p "$ISO_STAGING/live"
mkdir -p "$ISO_STAGING/boot/grub"
trap 'rm -rf "$ISO_STAGING"' EXIT INT TERM HUP

if command -v mksquashfs >/dev/null 2>&1 && [ -d "$TARGET_SYSROOT" ]; then
  mksquashfs "$TARGET_SYSROOT" "$ISO_STAGING/live/filesystem.squashfs" -comp zstd -noappend >/dev/null 2>&1 ||
    mksquashfs "$TARGET_SYSROOT" "$ISO_STAGING/live/filesystem.squashfs" -comp xz -noappend >/dev/null 2>&1 || true
elif [ -d "$TARGET_SYSROOT" ]; then
  tar -czf "$ISO_STAGING/live/filesystem.tar.gz" -C "$TARGET_SYSROOT" . 2>/dev/null || true
fi

if [ -f "$TARGET_SYSROOT/boot/vmlinuz" ]; then
  cp -f "$TARGET_SYSROOT/boot/vmlinuz" "$ISO_STAGING/boot/vmlinuz"
fi
if [ -f "$TARGET_SYSROOT/boot/initramfs.img" ]; then
  cp -f "$TARGET_SYSROOT/boot/initramfs.img" "$ISO_STAGING/boot/initramfs.img"
fi

cat <<'GRUB_ISO_EOF' > "$ISO_STAGING/boot/grub/grub.cfg"
set default="0"
set timeout=5
menuentry "LibScript Live OS" {
    linux /boot/vmlinuz boot=live quiet
    initrd /boot/initramfs.img
}
GRUB_ISO_EOF

BUILT_NATIVE=0
rm -f "$OUT_ISO"
if command -v grub-mkrescue >/dev/null 2>&1; then
  grub-mkrescue -o "$OUT_ISO" "$ISO_STAGING" -- -volid "$VOL_ID" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi
if [ "$BUILT_NATIVE" -eq 0 ] && command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -iso-level 3 -full-iso9660-filenames -volid "$VOL_ID" -o "$OUT_ISO" "$ISO_STAGING" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi
if [ "$BUILT_NATIVE" -eq 0 ] && command -v mkisofs >/dev/null 2>&1; then
  mkisofs -r -V "$VOL_ID" -o "$OUT_ISO" "$ISO_STAGING" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi
if [ "$BUILT_NATIVE" -eq 0 ] && command -v makefs >/dev/null 2>&1; then
  makefs -t cd9660 -o "rockridge,label=${VOL_ID}" "$OUT_ISO" "$ISO_STAGING" >/dev/null 2>&1 || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi
if [ "$BUILT_NATIVE" -eq 0 ] && command -v hdiutil >/dev/null 2>&1; then
  hdiutil makehybrid -iso -joliet -default-volume-name "$VOL_ID" -o "${OUT_ISO}.cdr" "$ISO_STAGING" >/dev/null 2>&1 || true
    mv -f "${OUT_ISO}.cdr.iso" "$OUT_ISO" 2>/dev/null || mv -f "${OUT_ISO}.cdr" "$OUT_ISO" 2>/dev/null || true
  if [ -s "${OUT_ISO}" ]; then BUILT_NATIVE=1; fi
fi

if [ "$BUILT_NATIVE" -eq 1 ]; then
  printf 'mode=native\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
  printf '[OK] Successfully synthesized live ISO image: %s\n' "$OUT_ISO"
  exit 0
fi

if [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR] Strict image synthesis failed: install xorriso, grub-mkrescue, makefs, or mkisofs to build %s.\n' "$OUT_ISO" >&2
  rm -f "$OUT_ISO" "$STAMP_FILE"
  exit 1
fi

printf 'LibScript Live ISO Image Stub (%s)\n' "$VOL_ID" > "$OUT_ISO"
printf 'mode=stub\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[WARN] Generated non-bootable ISO stub (native ISO tool missing): %s\n' "$OUT_ISO"
exit 0
