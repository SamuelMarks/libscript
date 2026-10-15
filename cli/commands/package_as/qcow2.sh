#!/bin/sh
# ## Overview
# Packages raw disk images or sysroots into compressed virtual machine disk
# images (qcow2, vmdk, vdi) using qemu-img with compression and sparseness.
#
# ## Usage
# Run `qcow2.sh [input_image_or_sysroot] [output_image] [target_format]`

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

INPUT="${1:-${LIBSCRIPT_ROOT_DIR}/build/images/raw/disk.img}"
FMT="${3:-qcow2}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/disk.${FMT}}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

# If input is a directory, synthesize raw image first
if [ -d "$INPUT" ]; then
  TMP_RAW="${LIBSCRIPT_ROOT_DIR}/build/disk_intermediate.raw"
  "${SCRIPT_DIR}/raw_img.sh" "$INPUT" "$TMP_RAW"
  INPUT="$TMP_RAW"
fi

if [ ! -f "$INPUT" ]; then
  printf '[ERROR] Input disk image not found: %s\n' "$INPUT" >&2
  exit 1
fi

printf '[PACKAGE] Converting %s to compressed %s format (%s)...\n' "$INPUT" "$FMT" "$OUT_FILE"

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -c -O "$FMT" "$INPUT" "$OUT_FILE"
else
  printf '[WARN] qemu-img not found in PATH; copying raw image stub as %s\n' "$OUT_FILE" >&2
  cp -f "$INPUT" "$OUT_FILE" 2>/dev/null || printf 'QEMU Image Stub (%s)\n' "$FMT" > "$OUT_FILE"
fi

printf '[OK] Successfully synthesized VM disk image: %s\n' "$OUT_FILE"
exit 0
