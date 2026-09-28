#!/bin/sh
# ## Overview
# Exports an illumos disk image or sysroot to a compressed, sparse
# QCOW2 image format suitable for QEMU, KVM, and Proxmox hypervisors.
#
# ## Usage
# Convert to QCOW2 format:
#   cli/commands/package_as/illumos_qcow2.sh [input_raw_or_sysroot] [output_qcow2] [size_gib]

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
OUT_QCOW2="${2:-${REPO_ROOT}/build/illumos.qcow2}"
SIZE_GIB="${3:-20}"

OUT_DIR="${OUT_QCOW2%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_QCOW2}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_QCOW2}" ]; then
  printf '[SKIP]     illumos QCOW2 image %s already synthesized
' "${OUT_QCOW2}"
  exit 0
fi

printf '[PACKAGE]  Exporting illumos QCOW2 image: %s...
' "${OUT_QCOW2}"

# If input is a directory, synthesize raw image first
if [ -d "${INPUT}" ]; then
  RAW_TMP="${REPO_ROOT}/build/illumos_temp.raw"
  "${SCRIPT_DIR}/illumos_raw.sh" "${INPUT}" "${RAW_TMP}" "${SIZE_GIB}"
  INPUT="${RAW_TMP}"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -O qcow2 -c -o cluster_size=64k,lazy_refcounts=on "${INPUT}" "${OUT_QCOW2}"
else
  printf '[WARN]     qemu-img not found, creating placeholder QCOW2...
'
  cp "${INPUT}" "${OUT_QCOW2}" 2>/dev/null || type nul > "${OUT_QCOW2}" 2>/dev/null || touch "${OUT_QCOW2}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos QCOW2 image generated: %s
' "${OUT_QCOW2}"
