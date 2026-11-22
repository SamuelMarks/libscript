#!/bin/sh
# ## Overview
# Installs a ReactOS base distribution, FreeLoader (freeldr.sys + freeldr.ini),
# unattend.inf, and pre-staged LibScript / RAPPS workloads onto a target partition.
#
# ## Usage
# ./synthesis/msi/live_installer/distro_installers/install_reactos.sh <target_dev> [target_dir] [filesystem]

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

TARGET_DEV="${1:-}"
TARGET_DIR="${2:-/mnt/target/reactos}"
FS_TYPE="${3:-fat32}"

if [ -z "$TARGET_DEV" ]; then
  printf '[ERROR] Target partition device path is required.\n' >&2
  exit 1
fi

STAMP_FILE="${TARGET_DIR}/.libscript_reactos_installed.stamp"
if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP] ReactOS already installed on %s (%s).\n' "$TARGET_DEV" "$TARGET_DIR"
  exit 0
fi

mkdir -p "$TARGET_DIR"
if [ -x "${LIBSCRIPT_ROOT_DIR}/synthesis/disk/format.sh" ]; then
  "${LIBSCRIPT_ROOT_DIR}/synthesis/disk/format.sh" "$TARGET_DEV" "$FS_TYPE" 'reactosroot' 2>/dev/null || true
fi

TMP_SYS="${TARGET_DIR}/.sysroot_stage"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" \
  "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/desktop-classic-i686.json" "$TMP_SYS"

cp -R "${TMP_SYS}/iso_root/." "$TARGET_DIR/"
rm -rf "$TMP_SYS"

mkdir -p "${TARGET_DIR}/EFI/reactos"
if [ -f "${TARGET_DIR}/EFI/BOOT/BOOTX64.EFI" ]; then
  cp -f "${TARGET_DIR}/EFI/BOOT/BOOTX64.EFI" "${TARGET_DIR}/EFI/reactos/bootx64.efi" 2>/dev/null || true
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] ReactOS deployed onto %s (%s).\n' "$TARGET_DEV" "$TARGET_DIR"
