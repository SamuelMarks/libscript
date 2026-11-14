#!/bin/sh
# ## Overview
# Packages a FreeBSD target sysroot into a bootable GPT raw disk image (.raw / .img)
# supporting both UFS2 and ZFS Boot Environments (zroot/ROOT/default), ESP loader.efi,
# and cross-OS rootless makefs + mkimg synthesis.
# ## Usage
# ./cli/commands/package_as/freebsd_raw.sh [--fs=ufs2|zfs] [--strict | --allow-stub] [sysroot_path] [output_raw] [size_gib]

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

FS_TYPE='ufs2'
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--fs=ufs2|zfs] [--strict | --allow-stub] [sysroot_path] [output_raw] [size_gib]\n' "$0"
      exit 0
      ;;
    --fs=*) FS_TYPE="${1#*=}"; shift ;;
    --strict) STRICT_BUILD=1; shift ;;
    --allow-stub) ALLOW_STUB=1; shift ;;
    *) break ;;
  esac
done

SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/freebsd-sysroot}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/freebsd.raw}"
SIZE_GIB="${3:-20}"
mkdir -p "$(dirname "${OUT_IMG}")" "$SYSROOT"

if grep -q 'zfs_enable="YES"' "${SYSROOT}/etc/rc.conf" 2>/dev/null; then
  FS_TYPE='zfs'
fi

STAMP_FILE="${OUT_IMG}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -s "${OUT_IMG}" ]; then
  if grep -q '^mode=stub$' "${STAMP_FILE}" 2>/dev/null && [ "$STRICT_BUILD" = "1" ]; then
    rm -f "${STAMP_FILE}"
  else
    printf '[SKIP]     FreeBSD raw image %s already generated\n' "${OUT_IMG}"
    exit 0
  fi
fi

MD_UNIT=''
TMP_MNT=''
TMP_STAGE="${LIBSCRIPT_ROOT_DIR}/build/fb_mkimg_$$"
mkdir -p "$TMP_STAGE"

# ## cleanup_freebsd_raw
# Unmounts temporary FreeBSD slices/ZFS pools and detaches mdconfig devices.
# shellcheck disable=SC2329
cleanup_freebsd_raw() {
  if [ -n "$TMP_MNT" ] && [ -d "$TMP_MNT" ]; then
    umount "${TMP_MNT}/boot/efi" >/dev/null 2>&1 || true
    umount "$TMP_MNT" >/dev/null 2>&1 || true
    rmdir "$TMP_MNT" >/dev/null 2>&1 || true
  fi
  if command -v zpool >/dev/null 2>&1; then
    zpool export -f zroot_build_$$ >/dev/null 2>&1 || true
  fi
  if [ -n "$MD_UNIT" ] && command -v mdconfig >/dev/null 2>&1; then
    mdconfig -d -u "$MD_UNIT" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_STAGE"
}
trap cleanup_freebsd_raw EXIT INT TERM HUP

printf '[PACKAGE]  Generating FreeBSD raw image (%s): %s (%s GiB)...\n' "$FS_TYPE" "${OUT_IMG}" "${SIZE_GIB}"
STAMP_MODE='stub'

# Cross-OS rootless path via FreeBSD makefs + mkimg
if command -v makefs >/dev/null 2>&1 && command -v mkimg >/dev/null 2>&1; then
  mkdir -p "${TMP_STAGE}/esp/EFI/BOOT"
  if [ -f "${SYSROOT}/boot/loader.efi" ]; then
    cp -f "${SYSROOT}/boot/loader.efi" "${TMP_STAGE}/esp/EFI/BOOT/BOOTX64.EFI"
  else
    printf 'FreeBSD UEFI Loader\n' > "${TMP_STAGE}/esp/EFI/BOOT/BOOTX64.EFI"
  fi
  makefs -t msdos -s 64m "${TMP_STAGE}/efiboot.img" "${TMP_STAGE}/esp" >/dev/null 2>&1 || true
  if [ "$FS_TYPE" = "zfs" ] && makefs -t zfs -s "${SIZE_GIB}g" -o poolname=zroot -o bootfs=zroot/ROOT/default -o rootpath=/ "${TMP_STAGE}/root.part" "${SYSROOT}" >/dev/null 2>&1; then
    mkimg -s gpt -f raw -p "efi:=${TMP_STAGE}/efiboot.img" -p "freebsd-zfs:=${TMP_STAGE}/root.part" -o "${OUT_IMG}" && STAMP_MODE='native' || true
  else
    makefs -t ffs -B little -M 512m "${TMP_STAGE}/root.part" "${SYSROOT}" >/dev/null 2>&1 || true
    if [ -s "${TMP_STAGE}/root.part" ]; then
      mkimg -s gpt -f raw -p "efi:=${TMP_STAGE}/efiboot.img" -p "freebsd-ufs:=${TMP_STAGE}/root.part" -o "${OUT_IMG}" && STAMP_MODE='native' || true
    fi
  fi
fi

# Native FreeBSD root mdconfig + gpart + zpool/newfs path
if [ "$STAMP_MODE" = "stub" ]; then
  if command -v truncate >/dev/null 2>&1; then
    truncate -s "${SIZE_GIB}G" "${OUT_IMG}"
  else
    dd if=/dev/zero of="${OUT_IMG}" bs=1M count=0 seek=$((SIZE_GIB * 1024)) 2>/dev/null
  fi
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true

  if [ "${UNAME:-}" = "FreeBSD" ] && [ "$(id -u)" -eq 0 ] && command -v mdconfig >/dev/null 2>&1 && command -v gpart >/dev/null 2>&1; then
    MD_DEV=$(mdconfig -a -t vnode -f "${OUT_IMG}")
    MD_UNIT="${MD_DEV#md}"
    gpart create -s gpt "${MD_DEV}"
    gpart add -t efi -s 200M -l efiboot0 "${MD_DEV}"
    gpart add -t freebsd-boot -s 512K -l gptboot0 "${MD_DEV}"
    TMP_MNT=$(mktemp -d)
    if command -v newfs_msdos >/dev/null 2>&1; then
      newfs_msdos -F 32 -c 1 "/dev/${MD_DEV}p1" >/dev/null 2>&1 || true
      mkdir -p "${TMP_STAGE}/esp_mnt"
      if mount -t msdosfs "/dev/${MD_DEV}p1" "${TMP_STAGE}/esp_mnt" 2>/dev/null; then
        mkdir -p "${TMP_STAGE}/esp_mnt/EFI/BOOT"
        [ -f "${SYSROOT}/boot/loader.efi" ] && cp -f "${SYSROOT}/boot/loader.efi" "${TMP_STAGE}/esp_mnt/EFI/BOOT/BOOTX64.EFI"
        umount "${TMP_STAGE}/esp_mnt" 2>/dev/null || true
      fi
    fi
    if [ "$FS_TYPE" = "zfs" ] && command -v zpool >/dev/null 2>&1; then
      if [ -f "${SYSROOT}/boot/pmbr" ] && [ -f "${SYSROOT}/boot/gptzfsboot" ]; then
        gpart bootcode -b "${SYSROOT}/boot/pmbr" -p "${SYSROOT}/boot/gptzfsboot" -i 2 "${MD_DEV}" || true
      fi
      gpart add -t freebsd-zfs -l zfs0 "${MD_DEV}"
      zpool create -f -R "${TMP_MNT}" -O compression=lz4 -O mountpoint=none "zroot_build_$$" "/dev/${MD_DEV}p3"
      zfs create -o mountpoint=none "zroot_build_$$/ROOT"
      zfs create -o mountpoint=/ "zroot_build_$$/ROOT/default"
      cp -a "${SYSROOT}/." "${TMP_MNT}/"
      zpool set "bootfs=zroot_build_$$/ROOT/default" "zroot_build_$$"
      zpool export "zroot_build_$$"
      STAMP_MODE='native'
    else
      if [ -f "${SYSROOT}/boot/pmbr" ] && [ -f "${SYSROOT}/boot/gptboot" ]; then
        gpart bootcode -b "${SYSROOT}/boot/pmbr" -p "${SYSROOT}/boot/gptboot" -i 2 "${MD_DEV}" || true
      fi
      gpart add -t freebsd-ufs -l rootfs0 "${MD_DEV}"
      newfs -U -j "/dev/${MD_DEV}p3" >/dev/null
      mount "/dev/${MD_DEV}p3" "${TMP_MNT}"
      cp -a "${SYSROOT}/." "${TMP_MNT}/"
      umount "${TMP_MNT}"
      STAMP_MODE='native'
    fi
  fi
fi

if [ "$STAMP_MODE" = "stub" ] && [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR]    Strict FreeBSD raw disk synthesis requires FreeBSD makefs+mkimg or native FreeBSD root mdconfig+gpart.\n' >&2
  rm -f "${OUT_IMG}" "${STAMP_FILE}"
  exit 1
fi

printf 'mode=%s\nfs=%s\ntimestamp=%s\n' "$STAMP_MODE" "$FS_TYPE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD raw image generated (%s): %s\n' "$STAMP_MODE" "${OUT_IMG}"
