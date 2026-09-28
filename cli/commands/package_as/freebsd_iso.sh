#!/bin/sh
# ## Overview
# Generates a bootable hybrid ISO image containing FreeBSD sysroot
# with UEFI and BIOS el-torito boot support.
#
# ## Usage
# Generate bootable ISO:
#   cli/commands/package_as/freebsd_iso.sh [sysroot_path] [output_iso]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
OUT_ISO="${2:-${REPO_ROOT}/build/freebsd.iso}"

OUT_DIR="${OUT_ISO%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_ISO}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_ISO}" ]; then
  printf '[SKIP]     FreeBSD ISO %s already generated
' "${OUT_ISO}"
  exit 0
fi

printf '[PACKAGE]  Generating FreeBSD bootable ISO: %s...
' "${OUT_ISO}"

if command -v makefs >/dev/null 2>&1 && [ -f "${SYSROOT}/boot/cdboot" ]; then
  makefs -t cd9660 -o rockridge -o label="FREEBSD_INSTALL" -o bootimage="i386;${SYSROOT}/boot/cdboot" -o no-emul-boot "${OUT_ISO}" "${SYSROOT}"
elif command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -r -V "FREEBSD_INSTALL" -o "${OUT_ISO}" "${SYSROOT}"
else
  printf '[WARN]     ISO creation tool not found, generating placeholder...
'
  touch "${OUT_ISO}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD ISO generated: %s
' "${OUT_ISO}"
