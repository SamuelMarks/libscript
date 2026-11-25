#!/bin/sh
# ## Overview
# Builds or repacks Microsoft MIT MS-DOS 1.25, 2.0, and 4.00 kernels (IO.SYS, MSDOS.SYS/MSDOS.COM,
# COMMAND.COM, MBR, and FAT12/FAT16-BIGDOS VBRs), compiling sanitize_cp437 and scp2nasm helpers.
#
# ## Usage
# ./_lib/kernel/msdos/build_msdos.sh <output_dir> [1.25|2.0|4.0]

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

OUT_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/msdos-stage}}"
DOS_VER="${2:-${MSDOS_VERSION:-4.0}}"
mkdir -p "${OUT_DIR}/tools"

STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/sanitize_cp437.c" "${OUT_DIR}/tools/sanitize_cp437"
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/scp2nasm.c" "${OUT_DIR}/tools/scp2nasm"
chmod +x "${OUT_DIR}/tools/sanitize_cp437" "${OUT_DIR}/tools/scp2nasm"

_emit_bin="${TMPDIR:-/tmp}/msdos_emit_$$"
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/emit_msdos_boot_c89.c" "${_emit_bin}"
"${_emit_bin}" "${OUT_DIR}" "${DOS_VER}"
rm -f "${_emit_bin}"
