#!/bin/sh
# ## Overview
# Packages a synthesized DOS sysroot into an El Torito bootable ISO9660 image (.iso)
# using xorriso/mkisofs when available or a bootable hybrid floppy/ISO image fallback.
#
# ## Usage
# ./synthesis/formats/dos_iso.sh <sysroot_dir> <output.iso>

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

SYSROOT="${1:?Missing sysroot}"
OUT_ISO="${2:?Missing output ISO path}"
ISO_STAGE="${TMPDIR:-/tmp}/dos_iso_$$"
mkdir -p "${ISO_STAGE}/BOOT" "$(dirname -- "${OUT_ISO}")"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/live_dos.sh" "${SYSROOT}" "${ISO_STAGE}/BOOT/FLOPPY.IMG"

if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -quiet -R -J -V "LIBSCRIPDOS" -b BOOT/FLOPPY.IMG -c BOOT/BOOT.CAT -o "${OUT_ISO}" "${ISO_STAGE}"
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -quiet -R -J -V "LIBSCRIPDOS" -b BOOT/FLOPPY.IMG -c BOOT/BOOT.CAT -o "${OUT_ISO}" "${ISO_STAGE}"
else
  cp -f "${ISO_STAGE}/BOOT/FLOPPY.IMG" "${OUT_ISO}"
fi
rm -rf "${ISO_STAGE}"
