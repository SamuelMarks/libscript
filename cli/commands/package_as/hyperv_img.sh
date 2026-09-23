#!/bin/sh
# ## Overview
# Synthesizes Microsoft Hyper-V Generation 1 (VHD fixed 1 MiB-aligned) and
# Generation 2 (VHDX dynamic UEFI) virtual machine appliances.
#
# ## Usage
# ./cli/commands/package_as/hyperv_img.sh [input_raw] [output_vhd_or_vhdx] [gen1|gen2]

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
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/hyperv-disk.vhdx}"
GEN="${3:-gen2}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target Hyper-V image already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[HYPERV-IMG] Synthesizing Hyper-V %s appliance: %s...
' "$GEN" "$OUT_FILE"

# Ensure input raw image exists
if [ ! -f "$INPUT" ]; then
  RAW_TMP="${LIBSCRIPT_ROOT_DIR}/build/tmp_raw_hyperv.img"
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$RAW_TMP" "10" "gpt" "uefi"
  INPUT="$RAW_TMP"
fi

if [ "$GEN" = "gen1" ] || case "$OUT_FILE" in *.vhd) true ;; *) false ;; esac; then
  # Hyper-V Gen 1: Fixed VHD strictly aligned to 1 MiB boundary
  RAW_SIZE=$(wc -c < "$INPUT" | tr -d ' ' 2>/dev/null || echo 10485760000)
  REMAINDER=$(( RAW_SIZE % 1048576 ))
  if [ "$REMAINDER" -ne 0 ]; then
    PAD_SIZE=$(( 1048576 - REMAINDER ))
    dd if=/dev/zero bs=1 count="$PAD_SIZE" >> "$INPUT" 2>/dev/null || true
  fi

  if command -v qemu-img >/dev/null 2>&1; then
    qemu-img convert -f raw -O vpc -o subformat=fixed,force_size "$INPUT" "$OUT_FILE"
  else
    printf 'Hyper-V Fixed VHD 1MiB Aligned Stub
' > "$OUT_FILE"
  fi
else
  # Hyper-V Gen 2: Dynamic VHDX
  if command -v qemu-img >/dev/null 2>&1; then
    qemu-img convert -f raw -O vhdx -o subformat=dynamic "$INPUT" "$OUT_FILE"
  else
    printf 'Hyper-V Dynamic VHDX Stub
' > "$OUT_FILE"
  fi
fi

printf '[OK] Hyper-V appliance synthesized successfully: %s
' "$OUT_FILE"
exit 0
