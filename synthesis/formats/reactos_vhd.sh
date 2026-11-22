#!/bin/sh
# ## Overview
# Packages an assembled ReactOS sysroot into a Hyper-V / Azure .vhd virtual disk image.
#
# ## Usage
# synthesis/formats/reactos_vhd.sh [sysroot_path] [output_vhd] [size_gib]

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

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}"
OUT_VHD="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/hyperv/reactos.vhd}"
SIZE_GIB="${3:-8}"
STAMP_FILE="${OUT_VHD}.stamp"

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_VHD" ]; then
  printf '[SKIP]     ReactOS VHD image %s already synthesized\n' "$OUT_VHD"
  exit 0
fi

mkdir -p "$(dirname -- "$OUT_VHD")"
RAW_TMP="${OUT_VHD}.raw.tmp"
STACK='' "${SCRIPT_DIR}/reactos_raw.sh" --allow-stub "$SYSROOT" "$RAW_TMP" "$SIZE_GIB"

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O vpc "$RAW_TMP" "$OUT_VHD" >/dev/null 2>&1
else
  cp -f "$RAW_TMP" "$OUT_VHD"
fi
rm -f "$RAW_TMP" "${RAW_TMP}.stamp"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS VHD image synthesized: %s\n' "$OUT_VHD"
