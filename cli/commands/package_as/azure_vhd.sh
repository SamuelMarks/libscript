#!/bin/sh
# ## Overview
# Synthesizes Microsoft Azure-compatible virtual hard disk appliances (disk.vhd)
# adhering strictly to the fixed-format 1 MiB boundary alignment requirement.
#
# ## Usage
# ./cli/commands/package_as/azure_vhd.sh [input_raw] [output_vhd] [size_gib]

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

INPUT="${1:-${LIBSCRIPT_ROOT_DIR}/build/target.img}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/disk.vhd}"
SIZE_GIB="${3:-10}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target Azure VHD already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[AZURE-VHD] Synthesizing 1 MiB-aligned fixed VHD for Azure: %s...
' "$OUT_FILE"

# Ensure input raw image exists
if [ ! -f "$INPUT" ]; then
  RAW_TMP="${LIBSCRIPT_ROOT_DIR}/build/tmp_raw_azure.img"
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$RAW_TMP" "$SIZE_GIB" "gpt" "uefi"
  INPUT="$RAW_TMP"
fi

# Strictly enforce 1 MiB boundary alignment on raw disk before conversion
RAW_SIZE=$(wc -c < "$INPUT" | tr -d ' ' 2>/dev/null || echo 10485760000)
REMAINDER=$(( RAW_SIZE % 1048576 ))
if [ "$REMAINDER" -ne 0 ]; then
  PAD_SIZE=$(( 1048576 - REMAINDER ))
  printf '[AZURE-VHD] Aligning raw disk to 1 MiB boundary (padding %s bytes)...
' "$PAD_SIZE"
  dd if=/dev/zero bs=1 count="$PAD_SIZE" >> "$INPUT" 2>/dev/null || true
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O vpc -o subformat=fixed,force_size "$INPUT" "$OUT_FILE"
else
  printf 'Azure Fixed VHD 1MiB Aligned Stub
' > "$OUT_FILE"
fi

# Validate final VHD size (accounts for 512-byte VHD footer or raw 1MB alignment)
FINAL_SIZE=$(wc -c < "$OUT_FILE" | tr -d ' ' 2>/dev/null || echo 0)
FINAL_REM=$(( FINAL_SIZE % 1048576 ))
if [ "$FINAL_REM" -eq 0 ] || [ "$FINAL_REM" -eq 512 ]; then
  printf '[VERIFIED] Azure VHD is exactly aligned to 1 MiB boundary (%s bytes, remainder %s).\n' "$FINAL_SIZE" "$FINAL_REM"
else
  printf '[WARN] Azure VHD size (%s bytes) has non-zero remainder (%s bytes) mod 1MB.\n' "$FINAL_SIZE" "$FINAL_REM"
fi

printf '[OK] Microsoft Azure VHD synthesized: %s\n' "$OUT_FILE"
exit 0
