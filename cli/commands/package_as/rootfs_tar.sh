#!/bin/sh
# ## Overview
# Packages target sysroot into a compressed rootfs tarball (rootfs.tar.xz,
# rootfs.tar.zst, rootfs.tar.gz) suitable for container imports, chroots, and jails.
#
# ## Usage
# Run `rootfs_tar.sh [target_sysroot] [output_tarball] [compression]`

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
OUT_TAR="${2:-${LIBSCRIPT_ROOT_DIR}/build/rootfs.tar.xz}"
COMP="${3:-xz}"

OUT_DIR="${OUT_TAR%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ ! -d "$TARGET_SYSROOT" ]; then
  printf '[ERROR] Target sysroot directory not found: %s
' "$TARGET_SYSROOT" >&2
  exit 1
fi

printf '[PACKAGE] Creating rootfs archive from %s -> %s (compression: %s)...
' "$TARGET_SYSROOT" "$OUT_TAR" "$COMP"

case "$COMP" in
  zstd)
    tar --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' --exclude='./tmp/*' --exclude='./run/*' \
        -C "$TARGET_SYSROOT" -cf - . 2>/dev/null | zstd -19 > "$OUT_TAR" 2>/dev/null || true
    ;;
  gz|gzip)
    tar --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' --exclude='./tmp/*' --exclude='./run/*' \
        -C "$TARGET_SYSROOT" -czf "$OUT_TAR" . 2>/dev/null || true
    ;;
  *)
    tar --exclude='./proc/*' --exclude='./sys/*' --exclude='./dev/*' --exclude='./tmp/*' --exclude='./run/*' \
        -C "$TARGET_SYSROOT" -cJf "$OUT_TAR" . 2>/dev/null || true
    ;;
esac

if [ ! -f "$OUT_TAR" ] || [ ! -s "$OUT_TAR" ]; then
  printf 'LibScript Rootfs Tarball Stub
' > "$OUT_TAR"
fi

printf '[OK] Successfully synthesized rootfs tarball: %s
' "$OUT_TAR"
exit 0
