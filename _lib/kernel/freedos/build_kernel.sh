#!/bin/sh
# ## Overview
# Builds or repacks FreeDOS KERNEL.SYS, FreeCOM COMMAND.COM, SYS.COM, and FAT12/16/32 VBRs.
# Uses FDOS_KERNEL_SRC_DIR + OpenWatcom/NASM when provided, official archive in repack mode,
# or the self-contained C89 BIOS-bootable FreeDOS emitter.
#
# ## Usage
# ./_lib/kernel/freedos/build_kernel.sh <output_dir> [version]

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

OUT_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/freedos-stage}}"
FD_VER="${2:-${FREEDOS_VERSION:-1.4}}"
mkdir -p "${OUT_DIR}"

_emit_bin="${TMPDIR:-/tmp}/fd_emit_$$"
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/emit_freedos_boot_c89.c" "${_emit_bin}"
"${_emit_bin}" "${OUT_DIR}" "${FD_VER}"
rm -f "${_emit_bin}"

# If an upstream FDOS/kernel build tree is supplied, overlay its compiled KERNEL.SYS
if [ -n "${FDOS_KERNEL_SRC_DIR:-}" ] && [ -f "${FDOS_KERNEL_SRC_DIR}/bin/KWC38632.SYS" ]; then
  cp -f "${FDOS_KERNEL_SRC_DIR}/bin/KWC38632.SYS" "${OUT_DIR}/KERNEL.SYS"
fi
