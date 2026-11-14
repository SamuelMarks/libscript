#!/bin/sh
# ## Overview
# Exports a target sysroot or ZFS boot environment into a compressed ZFS replication
# stream (.zfs.zst / .zfs.gz) for Linux OpenZFS, FreeBSD zroot BEs, and illumos Kayak.
# ## Usage
# ./cli/commands/package_as/zfs_stream.sh [--strict | --allow-stub] [target_sysroot] [output_stream] [pool_dataset]

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
      printf 'Usage: %s [--strict | --allow-stub] [target_sysroot] [output_stream] [pool_dataset]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --strict)
      STRICT_BUILD=1
      shift
      ;;
    --allow-stub)
      ALLOW_STUB=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

TARGET_SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}}"
OUT_STREAM="${2:-${LIBSCRIPT_ROOT_DIR}/build/images/zfs/rootfs.zfs.zst}"
DATASET="${3:-rpool/ROOT/default}"
STAMP_FILE="${OUT_STREAM}.stamp"

# ## can_build_zfs_stream
# Checks whether makefs -t zfs or root zpool/zfs send tools are available.
can_build_zfs_stream() {
  if command -v zfs >/dev/null 2>&1 && command -v zpool >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  return 1
}

if [ -f "$STAMP_FILE" ] && [ -s "$OUT_STREAM" ]; then
  if grep -q '^mode=stub$' "$STAMP_FILE" 2>/dev/null; then
    if [ "$STRICT_BUILD" = "1" ] || can_build_zfs_stream; then
      rm -f "$STAMP_FILE"
    else
      printf '[SKIP] ZFS replication stream already synthesized (stub): %s\n' "$OUT_STREAM"
      exit 0
    fi
  else
    printf '[SKIP] ZFS replication stream already synthesized: %s\n' "$OUT_STREAM"
    exit 0
  fi
fi

mkdir -p "$(dirname "$OUT_STREAM")" "$TARGET_SYSROOT"
POOL_NAME="${DATASET%%/*}"
REL_DS="${DATASET#*/}"
TMP_VDEV="${LIBSCRIPT_ROOT_DIR}/build/zfs_vdev_$$.img"
TMP_ALTROOT="${LIBSCRIPT_ROOT_DIR}/build/zfs_altroot_$$"
TMP_POOL="lszfs$$"

# ## cleanup_zfs_temp
# Exports temporary ZFS pool and removes backing file on exit or signal.
# shellcheck disable=SC2329
cleanup_zfs_temp() {
  if command -v zpool >/dev/null 2>&1; then
    zpool export -f "$TMP_POOL" >/dev/null 2>&1 || zpool destroy -f "$TMP_POOL" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_VDEV" "$TMP_ALTROOT"
}
trap cleanup_zfs_temp EXIT INT TERM HUP

BUILT_NATIVE=0
if can_build_zfs_stream; then
  printf '[PACKAGE] Synthesizing ZFS replication stream (%s:%s) -> %s...\n' "$POOL_NAME" "$REL_DS" "$OUT_STREAM"
  mkdir -p "$TMP_ALTROOT"
  truncate -s 512M "$TMP_VDEV" 2>/dev/null || dd if=/dev/zero of="$TMP_VDEV" bs=1M count=512 >/dev/null 2>&1
  if zpool create -f -R "$TMP_ALTROOT" -O compression=lz4 -O mountpoint=none "$TMP_POOL" "$TMP_VDEV" >/dev/null 2>&1; then
    zfs create -p -o mountpoint=/ "${TMP_POOL}/${REL_DS}" >/dev/null 2>&1 || true
    cp -a "${TARGET_SYSROOT}/." "${TMP_ALTROOT}/" 2>/dev/null || true
    zfs snapshot "${TMP_POOL}/${REL_DS}@install" >/dev/null 2>&1 || true
    if command -v zstd >/dev/null 2>&1; then
      zfs send -R "${TMP_POOL}/${REL_DS}@install" | zstd -q -o "$OUT_STREAM" -f
    else
      zfs send -R "${TMP_POOL}/${REL_DS}@install" | gzip -9 > "$OUT_STREAM"
    fi
    if [ -s "$OUT_STREAM" ]; then
      BUILT_NATIVE=1
    fi
  fi
fi

if [ "$BUILT_NATIVE" -eq 1 ]; then
  printf 'mode=native\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
  mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
  printf '[OK] Synthesized ZFS replication stream: %s\n' "$OUT_STREAM"
  exit 0
fi

if [ "$STRICT_BUILD" = "1" ] && [ "$ALLOW_STUB" != "1" ]; then
  printf '[ERROR] Strict ZFS stream synthesis requires root privileges with OpenZFS/illumos/FreeBSD zpool+zfs utilities.\n' >&2
  rm -f "$OUT_STREAM" "$STAMP_FILE"
  exit 1
fi

if command -v zstd >/dev/null 2>&1; then
  tar -cf - -C "$TARGET_SYSROOT" . 2>/dev/null | zstd -q -o "$OUT_STREAM" -f || printf 'LibScript ZFS Stream Fallback\n' > "$OUT_STREAM"
else
  tar -czf "$OUT_STREAM" -C "$TARGET_SYSROOT" . 2>/dev/null || printf 'LibScript ZFS Stream Fallback\n' > "$OUT_STREAM"
fi
printf 'mode=stub\ntimestamp=%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[WARN] OpenZFS zpool root unavailable; emitted compressed sysroot archive stub: %s\n' "$OUT_STREAM"
exit 0
