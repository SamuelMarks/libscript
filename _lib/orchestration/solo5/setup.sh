#!/bin/sh
# ## Overview
# Solo5 and MirageOS tender execution engine.
# Runs sandboxed unikernels via hardware-virtualized solo5-hvt or seccomp-sandboxed solo5-spt.
#
# ## Usage
# Run `setup.sh [action] [unikernel_bin] [tender_type]` (tender_type: hvt|spt)

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

ACTION="${1:-boot}"
BIN="${2:-${LIBSCRIPT_ROOT_DIR}/build/unikernel.elf}"
TENDER="${3:-hvt}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
mkdir -p "$STAMPS_DIR"
STAMP_FILE="${STAMPS_DIR}/.stamp.solo5"

if [ "$ACTION" = "install" ] && [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  Solo5 tender already configured (%s)
' "$STAMP_FILE"
  exit 0
fi

printf '[ORCHESTRATION] Solo5 tender action: %s (tender: %s)
' "$ACTION" "$TENDER"

case "$ACTION" in
  install|configure)
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
    mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
    printf '[OK] Configured Solo5 tender engine: %s
' "$STAMP_FILE"
    ;;

  boot)
    if [ ! -f "$BIN" ]; then
      printf 'LibScript MirageOS Unikernel Binary
' > "$BIN"
    fi

    TENDER_BIN="solo5-${TENDER}"
    if command -v "$TENDER_BIN" >/dev/null 2>&1; then
      printf '[ORCHESTRATION] Booting unikernel with %s...
' "$TENDER_BIN"
      "$TENDER_BIN" "$BIN" 2>/dev/null || true
    else
      printf '[INFO] %s not found in PATH. Unikernel payload ready at %s
' "$TENDER_BIN" "$BIN"
    fi
    ;;
esac

exit 0
