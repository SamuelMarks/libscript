#!/bin/sh
# ## Overview
# Exports a staged DOS sysroot as a bootable 1.44M (or 360K/720K) FAT12 floppy image (.img).
#
# ## Usage
# ./synthesis/formats/dos_floppy.sh <sysroot_dir> <output.img> [floppy-1440k|floppy-360k|floppy-720k]

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
OUT_PATH="${2:?Missing output path}"
MEDIA="${3:-floppy-1440k}"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/filesystem.sh" "${SYSROOT}" "${OUT_PATH}" "${MEDIA}"
