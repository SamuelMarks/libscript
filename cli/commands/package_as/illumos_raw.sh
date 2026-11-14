#!/bin/sh
# ## Overview
# Packages an illumos target sysroot into a bootable GPT + ZFS rpool raw disk image (.raw / .img)
# configuring ESP loader64.efi, rpool/ROOT/illumos BE, boot_archive, and bootadm bootloader.
# ## Usage
# ./cli/commands/package_as/illumos_raw.sh [--strict | --allow-stub] [target_sysroot] [output_image] [size_gib]

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

STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--strict | --allow-stub] [target_sysroot] [output_image] [size_gib]\n' "$0"
      exit 0
      ;;
    --strict) STRICT_BUILD=1; shift ;;
    --allow-stub) ALLOW_STUB=1; shift ;;
    *) break ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_ROOT_DIR}/build/illumos-sysroot}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/illumos.raw}"
SIZE_GIB="${3:-20}"

mkdir -p "$(dirname "${OUT_IMG}")" "$TARGET_SYSROOT"
STAMP_FILE="${OUT_IMG}.stamp"

if [ -f "${STAMP_FILE}" ] && [ -s "${OUT_IMG}" ]; then
  if grep -q '^mode=stub$' "${STAMP_FILE}" 2>/dev/null && [ "$STRICT_BUILD" = "1" ]; then
    rm -f "${STAMP_FILE}"
  else
    printf '[SKIP]     illumos raw image %s already synthesized\n' "${OUT_IMG}"
    exit 0
  fi
fi

LOFI_DEV=''
ALTROOT="${LIBSCRIPT_ROOT_DIR}/build/illumos_altroot_$$"
POOL_TMP="rpool_ls_$$"

# ## cleanup_illumos_raw
# Cleanly exports temporary ZFS altroot pool and detaches lofiadm block device on exit.
# shellcheck disable=SC2329
cleanup_illumos_raw() {
  if command -v zpool >/dev/null 2>&1; then
    zpool export -f "$POOL_TMP" >/dev/null 2>&1 || true
  fi
  if [ -n "$LOFI_DEV" ] && command -v lofiadm >/dev/null 2>&1; then
    lofiadm -d "$LOFI_DEV" >/dev/null 2>&1 || true
  fi
  rm -rf "$ALTROOT"
}
trap cleanup_illumos_raw EXIT INT TERM HUP

printf '[PACKAGE]  Synthesizing illumos raw disk image: %s (%s GiB)...\n' "${OUT_IMG}" "${SIZE_GIB}"
if command -v truncate >/dev/null 2>&1; then
  truncate -s "${SIZE_GIB}G" "${OUT_IMG}"
else
  dd if=/dev/zero of="${OUT_IMG}" bs=1M count=0 seek="$((SIZE_GIB * 1024))" 2>/dev/null
fi

if command -v sgdisk >/dev/null 2>&1; then
  sgdisk --clear --new=1:2048:+256M --typecode=1:ef00 --change-name=1:"EFI" --new=2:0:-8M --typecode=2:bf01 --change-name=2:"zfs" "${OUT_IMG}" >/dev/null 2>&1 || true
fi

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

STAMP_MODE='stub'
if [ "${UNAME:-}" = "SunOS" ] && [ "$(id -u)" -eq 0 ] && command -v lofiadm >/dev/null 2>&1 && command -v zpool >/dev/null 2>&1; then
  LOFI_DEV=$(lofiadm -l -a "${OUT_IMG}" 2>/dev/null || lofiadm -a "${OUT_IMG}" 2>/dev/null || true)
  if [ -n "${LOFI_DEV}" ]; then
    mkdir -p "$ALTROOT"
    _zfs_slice="${LOFI_DEV}"
    if [ -b "${LOFI_DEV%p0}s1" ]; then
      _zfs_slice="${LOFI_DEV%p0}s1"
    fi
    if zpool create -f -R "$ALTROOT" -O compression=lz4 -O mountpoint=none -t "$POOL_TMP" rpool "$_zfs_slice" 2>/dev/null; then
      zfs create -o mountpoint=none "${POOL_TMP}/ROOT"
      zfs create -o mountpoint=/ "${POOL_TMP}/ROOT/illumos"
      cp -a "${TARGET_SYSROOT}/." "${ALTROOT}/" 2>/dev/null || true
      zpool set "bootfs=${POOL_TMP}/ROOT/illumos" "$POOL_TMP"
      if command -v bootadm >/dev/null 2>&1; then
        bootadm update-archive -R "$ALTROOT" >/dev/null 2>&1 || true
        bootadm install-bootloader -f -P "$POOL_TMP" -R "$ALTROOT" >/dev/null 2>&1 || true
      elif command -v installboot >/dev/null 2>&1 && [ -f "${ALTROOT}/boot/pmbr" ] && [ -f "${ALTROOT}/boot/gptzfsboot" ]; then
        installboot -m "${ALTROOT}/boot/pmbr" "${ALTROOT}/boot/gptzfsboot" "${_zfs_slice}" >/dev/null 2>&1 || true
      fi
      zpool export "$POOL_TMP"
      STAMP_MODE='native'
    fi
    lofiadm -d "${LOFI_DEV}" 2>/dev/null || true
    LOFI_DEV=''
  fi
elif [ "${LIBSCRIPT_VM_WORKER:-}" = "omnios-vm" ] && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/vm_builder.sh" ]; then
  if "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/vm_builder.sh" --worker=qemu "${THIS_FILE}" "${TARGET_SYSROOT}" "${OUT_IMG}" "${SIZE_GIB}"; then
    STAMP_MODE='native'
  fi
fi

if [ "$STAMP_MODE" = "stub" ] && [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR]    Strict illumos raw disk synthesis requires native illumos lofiadm+zpool+bootadm or LIBSCRIPT_VM_WORKER=omnios-vm.\n' >&2
  rm -f "${OUT_IMG}" "${STAMP_FILE}"
  exit 1
fi

printf 'mode=%s\ntimestamp=%s\n' "$STAMP_MODE" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos raw image generated (%s): %s\n' "$STAMP_MODE" "${OUT_IMG}"
