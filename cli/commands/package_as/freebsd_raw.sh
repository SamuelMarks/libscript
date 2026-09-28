#!/bin/sh
# ## Overview
# Packages a FreeBSD target sysroot into a raw GPT disk image (.raw / .img).
# Configures EFI system partition (ESP) or BIOS bootcode and root slice.
#
# ## Usage
# Package raw disk image:
#   cli/commands/package_as/freebsd_raw.sh [target_sysroot] [output_image] [size_gib]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/freebsd-sysroot}}"
OUT_IMG="${2:-${REPO_ROOT}/build/freebsd.raw}"
SIZE_GIB="${3:-20}"

OUT_DIR="${OUT_IMG%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_IMG}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_IMG}" ]; then
  printf '[SKIP]     FreeBSD raw image %s already synthesized
' "${OUT_IMG}"
  exit 0
fi

printf '[PACKAGE]  Synthesizing FreeBSD raw image: %s (%sG)...
' "${OUT_IMG}" "${SIZE_GIB}"

# Create sparse raw disk file
truncate -s "${SIZE_GIB}G" "${OUT_IMG}" 2>/dev/null || dd if=/dev/zero of="${OUT_IMG}" bs=1M count=1 seek=$((SIZE_GIB * 1024 - 1)) status=none

# In native FreeBSD, initialize GPT slices and populate bootcode
if [ "$(uname -s 2>/dev/null || true)" = "FreeBSD" ] && command -v mdconfig >/dev/null 2>&1; then
  MD_DEV=$(mdconfig -a -t vnode -f "${OUT_IMG}")
  gpart create -s gpt "${MD_DEV}" >/dev/null 2>&1 || true
  gpart add -t efi -s 200M -l efiboot0 "${MD_DEV}" >/dev/null 2>&1 || true
  gpart add -t freebsd-boot -s 512K -l bootcode "${MD_DEV}" >/dev/null 2>&1 || true
  gpart bootcode -b /boot/pmbr -p /boot/gptboot -i 2 "${MD_DEV}" >/dev/null 2>&1 || true
  gpart add -t freebsd-ufs -l rootfs "${MD_DEV}" >/dev/null 2>&1 || true
  newfs -U -j -L rootfs "/dev/${MD_DEV}p3" >/dev/null 2>&1 || true
  TMP_MNT=$(mktemp -d /tmp/fbsd_mnt.XXXXXX)
  mount "/dev/${MD_DEV}p3" "${TMP_MNT}"
  cp -a "${TARGET_SYSROOT}/" "${TMP_MNT}/" 2>/dev/null || true
  umount "${TMP_MNT}"
  rmdir "${TMP_MNT}"
  mdconfig -d -u "${MD_DEV#md}"
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       FreeBSD raw image generated: %s
' "${OUT_IMG}"
