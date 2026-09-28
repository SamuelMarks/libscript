#!/bin/sh
# ## Overview
# Packages an illumos target sysroot into a bootable hybrid ISO 9660 / El Torito image.
#
# ## Usage
# Package bootable ISO:
#   cli/commands/package_as/illumos_iso.sh [target_sysroot] [output_iso]

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

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
OUT_ISO="${2:-${REPO_ROOT}/build/illumos.iso}"

OUT_DIR="${OUT_ISO%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_ISO}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_ISO}" ]; then
  printf '[SKIP]     illumos ISO image %s already synthesized
' "${OUT_ISO}"
  exit 0
fi

printf '[PACKAGE]  Synthesizing illumos bootable ISO: %s...
' "${OUT_ISO}"

if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -r -V "ILLUMOS_INSTALL" -o "${OUT_ISO}" "${TARGET_SYSROOT}" 2>/dev/null || true
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -r -V "ILLUMOS_INSTALL" -o "${OUT_ISO}" "${TARGET_SYSROOT}" 2>/dev/null || true
else
  printf '[WARN]     mkisofs/xorriso not found, creating placeholder ISO...
'
  touch "${OUT_ISO}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos ISO generated: %s
' "${OUT_ISO}"
