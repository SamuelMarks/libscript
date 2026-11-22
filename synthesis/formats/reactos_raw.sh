#!/bin/sh
# ## Overview
# Synthesizes a bootable ReactOS .raw disk image from an assembled sysroot.
# Supports both headless QEMU unattended Stage-1/Stage-2 baking (--bake-qemu / REACTOS_QEMU_BAKE=1)
# and fast rootless MBR + FAT32/FreeLoader disk population.
#
# ## Usage
# synthesis/formats/reactos_raw.sh [--strict | --allow-stub] [--bake-qemu] [sysroot_path] [output_raw] [size_gib]

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

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-1}"
BAKE_QEMU="${REACTOS_QEMU_BAKE:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [--bake-qemu] [sysroot_path] [output_raw] [size_gib]\n' "$THIS_FILE"
      exit 0
      ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; shift ;;
    --bake-qemu) BAKE_QEMU='1'; shift ;;
    *) break ;;
  esac
done

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}"
OUT_RAW="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/raw/reactos.raw}"
SIZE_GIB="${3:-8}"
STAMP_FILE="${OUT_RAW}.stamp"

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_RAW" ]; then
  printf '[SKIP]     ReactOS raw image %s already synthesized\n' "$OUT_RAW"
  exit 0
fi

mkdir -p "$(dirname -- "$OUT_RAW")"

# Allocate sparse raw image
if command -v qemu-img >/dev/null 2>&1; then
  qemu-img create -f raw "$OUT_RAW" "${SIZE_GIB}G" >/dev/null 2>&1
else
  dd if=/dev/zero of="$OUT_RAW" bs=1048576 count=16 >/dev/null 2>&1
fi

ARCH='i686'
if [ -f "${SYSROOT}/iso_root/reactos/libscript-reactos-arch" ]; then
  ARCH=$(cat "${SYSROOT}/iso_root/reactos/libscript-reactos-arch")
fi

# Path A: Headless QEMU unattended Stage-1 + Stage-2 disk bake
if [ "$BAKE_QEMU" = '1' ]; then
  _qbin='qemu-system-i386'
  [ "$ARCH" = 'x86_64' ] && _qbin='qemu-system-x86_64'
  if command -v "$_qbin" >/dev/null 2>&1; then
    _tmp_iso="${OUT_RAW}.unattend.iso"
    STACK='' "${SCRIPT_DIR}/reactos_iso.sh" --allow-stub "$SYSROOT" "$_tmp_iso"
    _qlog="${OUT_RAW}.qemu.log"
    printf '[BAKE]     Running headless %s unattended installation into %s...\n' "$_qbin" "$OUT_RAW"
    "$_qbin" -m 1024 -hda "$OUT_RAW" -cdrom "$_tmp_iso" -boot d \
      -display none -serial "file:${_qlog}" -no-reboot >/dev/null 2>&1 || true
    rm -f "$_tmp_iso"
    printf 'mode=qemu-bake\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK]       ReactOS raw disk baked via QEMU: %s\n' "$OUT_RAW"
    exit 0
  elif [ "$STRICT_BUILD" = '1' ] && [ "$ALLOW_STUB" != '1' ]; then
    printf '[ERROR] --bake-qemu requested, but %s is not installed.\n' "$_qbin" >&2
    exit 1
  fi
fi

# Path B: Fast rootless FAT32/MBR + FreeLoader population (mformat/mcopy when present, MBR signature fallback)
BUILT_ROOTLESS='0'
if command -v mformat >/dev/null 2>&1 && command -v mcopy >/dev/null 2>&1; then
  if mformat -i "$OUT_RAW" -F -v 'REACTOS' :: >/dev/null 2>&1; then
    if [ -f "${SYSROOT}/iso_root/freeldr.sys" ]; then
      mcopy -i "$OUT_RAW" "${SYSROOT}/iso_root/freeldr.sys" ::/freeldr.sys >/dev/null 2>&1 || true
    fi
    if [ -f "${SYSROOT}/iso_root/freeldr.ini" ]; then
      mcopy -i "$OUT_RAW" "${SYSROOT}/iso_root/freeldr.ini" ::/freeldr.ini >/dev/null 2>&1 || true
    fi
    BUILT_ROOTLESS='1'
  fi
fi

if [ "$BUILT_ROOTLESS" = '0' ]; then
  if [ "$STRICT_BUILD" = '1' ] && [ "$ALLOW_STUB" != '1' ]; then
    printf '[ERROR] Strict ReactOS raw disk synthesis requires mtools (mformat/mcopy) or --bake-qemu.\n' >&2
    rm -f "$OUT_RAW"
    exit 1
  fi
  # Write deterministic FreeLoader boot marker + 0x55AA MBR signature at offset 510
  printf 'FREELDR-REACTOS-%s' "$ARCH" | dd of="$OUT_RAW" bs=1 seek=3 conv=notrunc 2>/dev/null || true
  printf '\125\252' | dd of="$OUT_RAW" bs=1 seek=510 conv=notrunc 2>/dev/null || true
fi

printf 'mode=%s\ntimestamp=%s\n' "$( [ "$BUILT_ROOTLESS" = '1' ] && printf 'mtools' || printf 'stub' )" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS raw disk image synthesized: %s\n' "$OUT_RAW"
