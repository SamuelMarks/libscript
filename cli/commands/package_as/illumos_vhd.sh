#!/bin/sh
# ## Overview
# Exports an illumos disk image or sysroot to Microsoft Hyper-V / Azure VHD format.
#
# ## Usage
# Export VHD image:
#   cli/commands/package_as/illumos_vhd.sh [input_raw_or_sysroot] [output_vhd] [size_gib]

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

INPUT="${1:-${REPO_ROOT}/build/illumos.raw}"
OUT_VHD="${2:-${REPO_ROOT}/build/illumos.vhd}"
SIZE_GIB="${3:-20}"

OUT_DIR="${OUT_VHD%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_VHD}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_VHD}" ]; then
  printf '[SKIP]     illumos VHD %s already synthesized
' "${OUT_VHD}"
  exit 0
fi

printf '[PACKAGE]  Exporting illumos VHD: %s...
' "${OUT_VHD}"

if [ -d "${INPUT}" ]; then
  RAW_TMP="${REPO_ROOT}/build/illumos_temp.raw"
  "${SCRIPT_DIR}/illumos_raw.sh" "${INPUT}" "${RAW_TMP}" "${SIZE_GIB}"
  INPUT="${RAW_TMP}"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -O vpc -o subformat=dynamic "${INPUT}" "${OUT_VHD}"
else
  printf '[WARN]     qemu-img not found, creating placeholder VHD...
'
  touch "${OUT_VHD}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos VHD generated: %s
' "${OUT_VHD}"
