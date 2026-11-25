#!/bin/sh
# ## Overview
# Compiles mkdosfs_img.c (rootless C89 FAT12/FAT16/FAT32 + MBR/VBR packer) and packs
# LIBSCRIPT_TARGET_SYSROOT into a deterministic bootable floppy or hard-disk image.
#
# ## Usage
# ./synthesis/distro/dos/filesystem.sh <sysroot_dir> <output_img> [media_type]

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
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/synthesis/dos.raw}"
MEDIA="${3:-${LIBSCRIPT_DOS_MEDIA_TYPE:-auto}}"
DOS_OS="${LIBSCRIPT_TARGET_OS:-freedos}"
STRATUM="${LIBSCRIPT_DOS_STRATUM:-dos32-dpmi}"

if [ "${MEDIA}" = 'auto' ]; then
  if [ "${STRATUM}" = 'dos16-fcb' ] || [ "${STRATUM}" = 'dos16-handle' ]; then
    MEDIA='floppy-1440k'
  elif [ "${DOS_OS}" = 'freedos' ]; then
    MEDIA='hdd-fat32'
  else
    MEDIA='hdd-fat16'
  fi
fi

# ## ensure_mkdosfs_bin
# Compiles and caches mkdosfs_img inside build/tools/.
ensure_mkdosfs_bin() {
  _bin="${LIBSCRIPT_ROOT_DIR}/build/tools/mkdosfs_img"
  if [ -x "${_bin}" ] && [ ! "${SCRIPT_DIR}/src/mkdosfs_img.c" -nt "${_bin}" ]; then
    printf '%s\n' "${_bin}"
    return 0
  fi
  mkdir -p "${LIBSCRIPT_ROOT_DIR}/build/tools"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/mkdosfs_img.c" "${_bin}" >&2
  printf '%s\n' "${_bin}"
}

MKFAT_BIN=$(ensure_mkdosfs_bin)
mkdir -p "$(dirname -- "${OUT_IMG}")"

VBR_OPT=''
MBR_OPT=''
FLAT_OPT=''
[ "${STRATUM}" = 'dos16-fcb' ] && FLAT_OPT='--flat-only'

if [ "${DOS_OS}" = 'freedos' ]; then
  for _fd_cand in "${SYSROOT}/BOOT" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freedos/default/boot"; do
    case "${MEDIA}" in
      hdd-fat32) [ -f "${_fd_cand}/fat32lba.bin" ] && VBR_OPT="--vbr=${_fd_cand}/fat32lba.bin" ;;
      hdd-fat16) [ -f "${_fd_cand}/fat16.bin" ] && VBR_OPT="--vbr=${_fd_cand}/fat16.bin" ;;
      *) [ -f "${_fd_cand}/fat12.bin" ] && VBR_OPT="--vbr=${_fd_cand}/fat12.bin" ;;
    esac
    [ -n "${VBR_OPT}" ] && break
  done
  _ms_boot="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos/default/boot"
  [ -f "${_ms_boot}/mbr_dos.bin" ] && MBR_OPT="--mbr=${_ms_boot}/mbr_dos.bin"
else
  _ms_ver="${LIBSCRIPT_DOS_VERSION:-4.0}"
  for _ms_cand in "${SYSROOT}/BOOT" "${SYSROOT}/opt/libscript/msdos/${_ms_ver}/boot" "${SYSROOT}/opt/libscript/MSDOS/${_ms_ver}/boot" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/msdos/${_ms_ver}/boot"; do
    if [ -z "${VBR_OPT}" ]; then
      if [ "${MEDIA}" = 'hdd-fat16' ] && [ -f "${_ms_cand}/boot_fat16_bigdos.bin" ]; then
        VBR_OPT="--vbr=${_ms_cand}/boot_fat16_bigdos.bin"
      elif [ -f "${_ms_cand}/boot_fat12.bin" ]; then
        VBR_OPT="--vbr=${_ms_cand}/boot_fat12.bin"
      fi
    fi
    if [ -z "${MBR_OPT}" ] && [ -f "${_ms_cand}/mbr_dos.bin" ]; then
      MBR_OPT="--mbr=${_ms_cand}/mbr_dos.bin"
    fi
  done
fi

# Clean internal solver var/ stamp tree on flat-only 1.25 sysroots before packing
for _unix_meta in var opt usr "etc/profile.d"; do
  [ -d "${SYSROOT:?}/${_unix_meta}" ] && rm -rf "${SYSROOT:?}/${_unix_meta}"
done
if [ -n "${FLAT_OPT}" ] && [ -d "${SYSROOT:?}/etc" ]; then
  rm -rf "${SYSROOT:?}/etc"
fi

set -- "--sysroot=${SYSROOT}" "--out=${OUT_IMG}" "--media=${MEDIA}" "--label=LIBSCRIP"
[ -n "${VBR_OPT}" ] && set -- "$@" "${VBR_OPT}"
[ -n "${MBR_OPT}" ] && set -- "$@" "${MBR_OPT}"
[ -n "${FLAT_OPT}" ] && set -- "$@" "${FLAT_OPT}"
"${MKFAT_BIN}" "$@"
