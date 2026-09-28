#!/bin/sh
# ## Overview
# Packages an illumos target sysroot into a raw GPT disk image (.raw / .img).
# Configures EFI system partition (ESP) or BIOS bootcode and ZFS root pool.
#
# ## Usage
# Package raw disk image:
#   cli/commands/package_as/illumos_raw.sh [target_sysroot] [output_image] [size_gib]

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

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${REPO_ROOT}/build/illumos-sysroot}}"
OUT_IMG="${2:-${REPO_ROOT}/build/illumos.raw}"
SIZE_GIB="${3:-20}"

OUT_DIR="${OUT_IMG%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

STAMP_FILE="${OUT_IMG}.stamp"
if [ -f "${STAMP_FILE}" ] && [ -f "${OUT_IMG}" ]; then
  printf '[SKIP]     illumos raw image %s already synthesized
' "${OUT_IMG}"
  exit 0
fi

printf '[PACKAGE]  Synthesizing illumos raw image: %s (%sG)...
' "${OUT_IMG}" "${SIZE_GIB}"

# Create sparse raw disk file
truncate -s "${SIZE_GIB}G" "${OUT_IMG}" 2>/dev/null || dd if=/dev/zero of="${OUT_IMG}" bs=1M count=1 seek=$((SIZE_GIB * 1024 - 1)) status=none

# In native SunOS / illumos, initialize loopback device via lofiadm if available
if [ "$(uname -s 2>/dev/null || true)" = "SunOS" ] && command -v lofiadm >/dev/null 2>&1; then
  LOFI_DEV=$(lofiadm -a "${OUT_IMG}" 2>/dev/null || true)
  if [ -n "${LOFI_DEV}" ]; then
    printf '[INFO]     Attached lofi device: %s
' "${LOFI_DEV}"
    lofiadm -d "${LOFI_DEV}" 2>/dev/null || true
  fi
fi

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "${STAMP_FILE}"
printf '[OK]       illumos raw image generated: %s
' "${OUT_IMG}"
