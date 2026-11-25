#!/bin/sh
# ## Overview
# Orchestrates full T3 DOS distribution assembly (base -> dpmi -> network -> config -> filesystem)
# idempotently into LIBSCRIPT_TARGET_SYSROOT and emits a ready-to-boot raw/floppy disk image.
#
# ## Usage
# ./synthesis/distro/dos/assemble.sh [sysroot_dir] [output_disk]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/dos-sysroot}}"
OUT_DISK="${2:-${SYSROOT}.disk.img}"

export LIBSCRIPT_TARGET_SYSROOT="${SYSROOT}"
STACK='' "${SCRIPT_DIR}/base.sh" "${SYSROOT}"
STACK='' "${SCRIPT_DIR}/dpmi.sh" "${SYSROOT}"
STACK='' "${SCRIPT_DIR}/network.sh" "${SYSROOT}"
STACK='' "${SCRIPT_DIR}/config.sh" "${SYSROOT}"
STACK='' "${SCRIPT_DIR}/filesystem.sh" "${SYSROOT}" "${OUT_DISK}"
