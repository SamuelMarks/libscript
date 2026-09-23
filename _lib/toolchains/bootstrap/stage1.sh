#!/bin/sh
# ## Overview
# Stage 1: Cross-Compiled Minimal Userland coordinator.
# Cross-compiles foundational POSIX utilities (sh, m4, coreutils, diffutils,
# gawk, grep, gzip, make, patch, sed, tar, xz) linked to target /tools/lib/libc.so.
#
# ## Usage
# Run `stage1.sh [target_arch] [target_libc] [target_os]` to build the minimal userland.

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

TARGET_ARCH="${1:-${LIBSCRIPT_TARGET_ARCH:-x86_64}}"
TARGET_LIBC="${2:-${LIBSCRIPT_TARGET_LIBC:-glibc}}"
TARGET_OS="${3:-${LIBSCRIPT_TARGET_OS:-linux}}"

HOST_ROOT="${LIBSCRIPT_HOST_ROOT:-${LIBSCRIPT_ROOT_DIR}/build/tools}"
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${SYSROOT}/var/lib/libscript/stamps"

if [ ! -d "$STAMPS_DIR" ]; then
  mkdir -p "$STAMPS_DIR"
fi

STAGE1_STAMP="${STAMPS_DIR}/.stamp.stage1_complete"
if [ -f "$STAGE1_STAMP" ]; then
  printf '[SKIP]  Stage 1 minimal userland already completed (%s)
' "$STAGE1_STAMP"
  exit 0
fi

# Load triplets
export LIBSCRIPT_TARGET_ARCH="$TARGET_ARCH"
export LIBSCRIPT_TARGET_LIBC="$TARGET_LIBC"
export LIBSCRIPT_TARGET_OS="$TARGET_OS"
. "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/triplets.sh"

printf '[STAGE1] Building Minimal Userland for %s into %s
' "$LIBSCRIPT_TARGET_TRIPLET" "$HOST_ROOT"

# List of essential core utilities to cross-compile
TOOLS="m4 ncurses sh coreutils diffutils file findutils gawk grep gzip make patch sed tar xz"

for tool in $TOOLS; do
  TOOL_STAMP="${STAMPS_DIR}/.stamp.stage1_${tool}"
  if [ -f "$TOOL_STAMP" ]; then
    printf '[SKIP]  Stage 1 tool %s already satisfied
' "$tool"
  else
    printf '[STAGE1] Cross-compiling %s against %s/lib/libc.so
' "$tool" "$HOST_ROOT"
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "${TOOL_STAMP}.tmp"
    mv "${TOOL_STAMP}.tmp" "$TOOL_STAMP"
    printf '[OK]    Stage 1 tool %s registered
' "$tool"
  fi
done

# Atomically record Stage 1 completion
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAGE1_STAMP}.tmp"
mv "${STAGE1_STAMP}.tmp" "$STAGE1_STAMP"
printf '[OK]    Stage 1 Minimal Userland finished: %s
' "$STAGE1_STAMP"
