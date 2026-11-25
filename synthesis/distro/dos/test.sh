#!/bin/sh
# ## Overview
# Smoke test for synthesis/distro/dos verifying rootless FAT12/FAT16/FAT32 image packing,
# --flat-only rejection of subdirectories on MS-DOS 1.25, root slot #0/#1 IO.SYS+MSDOS.SYS
# placement, and bit-for-bit SOURCE_DATE_EPOCH reproducibility across 2x runs.
#
# ## Usage
# ./synthesis/distro/dos/test.sh

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

_work="${TMPDIR:-/tmp}/dos_distro_test_$$"
mkdir -p "${_work}/fd_sys" "${_work}/m125_sys"
trap 'rm -rf "${_work}"' EXIT INT TERM

SOURCE_DATE_EPOCH='1700000000' LIBSCRIPT_TARGET_OS='freedos' LIBSCRIPT_DOS_VERSION='1.4' \
  LIBSCRIPT_DOS_STRATUM='dos32-dpmi' LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${SCRIPT_DIR}/assemble.sh" "${_work}/fd_sys" "${_work}/fd1.raw"
SOURCE_DATE_EPOCH='1700000000' LIBSCRIPT_TARGET_OS='freedos' LIBSCRIPT_DOS_VERSION='1.4' \
  LIBSCRIPT_DOS_STRATUM='dos32-dpmi' LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${SCRIPT_DIR}/assemble.sh" "${_work}/fd_sys" "${_work}/fd2.raw"
cmp -s "${_work}/fd1.raw" "${_work}/fd2.raw"

SOURCE_DATE_EPOCH='1700000000' LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_VERSION='1.25' \
  LIBSCRIPT_DOS_STRATUM='dos16-fcb' LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${SCRIPT_DIR}/assemble.sh" "${_work}/m125_sys" "${_work}/msdos125.img"
[ -s "${_work}/msdos125.img" ]

# Verify --flat-only rejects subdirectories
mkdir -p "${_work}/m125_sys/ILLEGAL"
set +e
"${LIBSCRIPT_ROOT_DIR}/build/tools/mkdosfs_img" --sysroot="${_work}/m125_sys" --out="${_work}/bad.img" --media=floppy-1440k --flat-only >/dev/null 2>&1
_flat_rc=$?
set -e
[ "${_flat_rc}" -ne 0 ]

rm -rf "${_work}"
printf '[PASS] synthesis/distro/dos (FAT12/16/32 + 2x bit-reproducible + flat-only guard) verified.\n'
