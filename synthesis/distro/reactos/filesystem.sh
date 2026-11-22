#!/bin/sh
# ## Overview
# Configures the ReactOS root filesystem driver (fat32 FASTFAT, btrfs WinBtrfs, or ntfs)
# and injects serial console debugging parameters into freeldr.ini idempotently.
#
# ## Usage
# ./synthesis/distro/reactos/filesystem.sh [sysroot_path] [filesystem] [serial_debug]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"
FS_TYPE="${2:-fat32}"
SERIAL_DEBUG="${3:-true}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/filesystem_${FS_TYPE}.stamp"
ISO_ROOT="${SYSROOT}/iso_root"

mkdir -p "$STAMP_DIR" "${ISO_ROOT}/reactos/system32/drivers"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS filesystem (%s) already configured in %s\n' "$FS_TYPE" "$SYSROOT"
  exit 0
fi

case "$FS_TYPE" in
  fat32)
    printf 'driver=fastfat.sys\nformat_code=1\n' > "${ISO_ROOT}/reactos/filesystem.conf"
    [ -f "${ISO_ROOT}/reactos/system32/drivers/fastfat.sys" ] || printf 'FASTFAT_SYS\n' > "${ISO_ROOT}/reactos/system32/drivers/fastfat.sys"
    ;;
  btrfs)
    printf 'driver=btrfs.sys\ndll=ubtrfs.dll\nformat_code=2\n' > "${ISO_ROOT}/reactos/filesystem.conf"
    [ -f "${ISO_ROOT}/reactos/system32/drivers/btrfs.sys" ] || printf 'WINBTRFS_SYS\n' > "${ISO_ROOT}/reactos/system32/drivers/btrfs.sys"
    ;;
  ntfs)
    printf 'driver=ntfs.sys\nformat_code=3\n' > "${ISO_ROOT}/reactos/filesystem.conf"
    [ -f "${ISO_ROOT}/reactos/system32/drivers/ntfs.sys" ] || printf 'NTFS_SYS\n' > "${ISO_ROOT}/reactos/system32/drivers/ntfs.sys"
    ;;
  *)
    printf '[ERROR] Unsupported ReactOS filesystem "%s" (expected fat32, btrfs, or ntfs).\n' "$FS_TYPE" >&2
    exit 1
    ;;
esac

if [ "$SERIAL_DEBUG" = 'true' ] || [ "$SERIAL_DEBUG" = '1' ]; then
  if [ -f "${ISO_ROOT}/freeldr.ini" ] && ! grep -q '/DEBUGPORT=COM1' "${ISO_ROOT}/freeldr.ini" 2>/dev/null; then
    awk '
      /^Options=/ && $0 !~ /DEBUGPORT=COM1/ {
        print $0 " /DEBUG /DEBUGPORT=COM1 /BAUDRATE=115200 /SOS"
        next
      }
      { print }
    ' "${ISO_ROOT}/freeldr.ini" > "${ISO_ROOT}/freeldr.ini.tmp"
    mv "${ISO_ROOT}/freeldr.ini.tmp" "${ISO_ROOT}/freeldr.ini"
  fi
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS filesystem (%s, serial_debug=%s) configured.\n' "$FS_TYPE" "$SERIAL_DEBUG"
