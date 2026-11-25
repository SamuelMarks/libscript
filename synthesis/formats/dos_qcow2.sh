#!/bin/sh
# ## Overview
# Converts a synthesized DOS raw/floppy disk image into qcow2 virtual disk format via qemu-img.
#
# ## Usage
# ./synthesis/formats/dos_qcow2.sh <sysroot_dir> <output.qcow2>

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
RAW_TMP="${OUT_PATH}.raw.tmp"
STACK='' "${SCRIPT_DIR}/dos_raw.sh" "${SYSROOT}" "${RAW_TMP}"
if command -v qemu-img >/dev/null 2>&1; then
  qemu-img convert -f raw -O "qcow2" "${RAW_TMP}" "${OUT_PATH}"
  rm -f "${RAW_TMP}"
else
  mv "${RAW_TMP}" "${OUT_PATH}"
fi
