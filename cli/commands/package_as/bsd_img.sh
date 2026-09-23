#!/bin/sh
# ## Overview
# Packages FreeBSD target sysroot into a bootable UFS/ZFS disk image (.img)
# suitable for bhyve hypervisors, QEMU VMs, or bare-metal storage drives.
#
# ## Usage
# Run `bsd_img.sh [target_sysroot] [output_image] [size_gib]`

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
export LIBSCRIPT_ROOT_DIR

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_IMG="${2:-${LIBSCRIPT_ROOT_DIR}/build/freebsd.img}"
SIZE_GIB="${3:-12}"

OUT_DIR="${OUT_IMG%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

printf '[PACKAGE] Synthesizing FreeBSD bootable disk image: %s (%sG)...
' "$OUT_IMG" "$SIZE_GIB"

"${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$OUT_IMG" "$SIZE_GIB" "bsd-slice" "freebsd"

if [ -d "$TARGET_SYSROOT" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/freebsd/setup.sh" compile "$TARGET_SYSROOT"
fi

printf '[OK] Successfully synthesized FreeBSD disk image: %s
' "$OUT_IMG"
exit 0
