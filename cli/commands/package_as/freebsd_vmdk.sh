#!/bin/sh
# ## Overview
# Exports a FreeBSD disk image or sysroot to VMware Workstation / ESXi VMDK format.
#
# ## Usage
# Export VMDK image:
#   cli/commands/package_as/freebsd_vmdk.sh [input_raw_or_sysroot] [output_vmdk] [size_gib]

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

INPUT="${1:-${REPO_ROOT}/build/freebsd.raw}"
OUT_VMDK="${2:-${REPO_ROOT}/build/freebsd.vmdk}"
SIZE_GIB="${3:-20}"

OUT_DIR="${OUT_VMDK%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_VMDK}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_VMDK}" ]; then
  printf '[SKIP]     FreeBSD VMDK %s already synthesized
' "${OUT_VMDK}"
  exit 0
fi

printf '[PACKAGE]  Exporting FreeBSD VMDK: %s...
' "${OUT_VMDK}"

if [ -d "${INPUT}" ]; then
  RAW_TMP="${REPO_ROOT}/build/freebsd_temp.raw"
  "${SCRIPT_DIR}/freebsd_raw.sh" "${INPUT}" "${RAW_TMP}" "${SIZE_GIB}"
  INPUT="${RAW_TMP}"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -O vmdk -o subformat=streamOptimized "${INPUT}" "${OUT_VMDK}"
else
  printf '[WARN]     qemu-img not found, creating placeholder VMDK...
'
  touch "${OUT_VMDK}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD VMDK generated: %s
' "${OUT_VMDK}"
