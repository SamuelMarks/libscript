#!/bin/sh
# ## Overview
# Orchestrates rootfs staging for target operating system builds.
# Initializes the FHS directory layout, default configuration skeletons,
# stamp tracking directories, and file permissions within the target sysroot.
#
# ## Usage
# Execute with target sysroot directory:
#   ./_lib/orchestration/rootfs.sh <target_sysroot> [--force]

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

TARGET_DIR="${1:-${LIBSCRIPT_TARGET_SYSROOT:-}}"

if [ -z "$TARGET_DIR" ]; then
  printf '[ERROR] Target sysroot directory required.
' >&2
  printf 'Usage: %s <target_sysroot> [--force]
' "$THIS_FILE" >&2
  exit 1
fi

FORCE=0
if [ "${2:-}" = "--force" ]; then
  FORCE=1
fi

STAMP_DIR="$TARGET_DIR/var/lib/libscript/stamps"
mkdir -p "$STAMP_DIR"

if [ "$FORCE" -eq 0 ] && [ -f "$STAMP_DIR/.stamp.rootfs_staged" ]; then
  printf '[INFO] Target rootfs already staged at %s. Skipping.
' "$TARGET_DIR"
  exit 0
fi

printf '[INFO] Staging target rootfs at: %s
' "$TARGET_DIR"

# 1. Initialize FHS layout and default files
"$SCRIPT_DIR/create_fhs_layout.sh" "$TARGET_DIR"

# 2. Sanitize permissions across sysroot
if [ "$(id -u 2>/dev/null || printf '%s' '1000')" -eq 0 ]; then
  chown -R 0:0 "$TARGET_DIR" 2>/dev/null || true
fi

touch "$STAMP_DIR/.stamp.rootfs_staged"
printf '[INFO] Rootfs staging completed successfully: %s
' "$TARGET_DIR"
exit 0
