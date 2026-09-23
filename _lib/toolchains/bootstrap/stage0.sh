#!/bin/sh
# ## Overview
# Stage 0: Host-Driven Cross-Toolchain bootstrap coordinator.
# Orchestrates Cross-Binutils Pass 1, GCC Pass 1, Kernel Headers, Target LibC,
# and Cross-GCC Pass 2 into LIBSCRIPT_HOST_ROOT (/tools).
#
# ## Usage
# Run `stage0.sh [target_arch] [target_libc] [target_os]` to build the initial cross toolchain.

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

if [ ! -d "$HOST_ROOT" ]; then
  mkdir -p "$HOST_ROOT"
fi

STAGE0_STAMP="${STAMPS_DIR}/.stamp.stage0_complete"
if [ -f "$STAGE0_STAMP" ]; then
  printf '[SKIP]  Stage 0 toolchain bootstrap already completed (%s)
' "$STAGE0_STAMP"
  exit 0
fi

# Load triplets
export LIBSCRIPT_TARGET_ARCH="$TARGET_ARCH"
export LIBSCRIPT_TARGET_LIBC="$TARGET_LIBC"
export LIBSCRIPT_TARGET_OS="$TARGET_OS"
. "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/triplets.sh"

printf '[STAGE0] Bootstrapping Cross-Toolchain for %s into %s
' "$LIBSCRIPT_TARGET_TRIPLET" "$HOST_ROOT"

# Check Binutils Pass 1
BINUTILS_STAMP="${STAMPS_DIR}/.stamp.stage0_binutils_pass1"
if [ ! -f "$BINUTILS_STAMP" ]; then
  printf '[STAGE0] Building Binutils Pass 1 (--target=%s --prefix=%s --with-sysroot=%s)
' "$LIBSCRIPT_TARGET_TRIPLET" "$HOST_ROOT" "$SYSROOT"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${BINUTILS_STAMP}.tmp"
  mv "${BINUTILS_STAMP}.tmp" "$BINUTILS_STAMP"
fi

# Check GCC Pass 1
GCC1_STAMP="${STAMPS_DIR}/.stamp.stage0_gcc_pass1"
if [ ! -f "$GCC1_STAMP" ]; then
  printf '[STAGE0] Building GCC Pass 1 (--target=%s --without-headers --with-newlib)
' "$LIBSCRIPT_TARGET_TRIPLET"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${GCC1_STAMP}.tmp"
  mv "${GCC1_STAMP}.tmp" "$GCC1_STAMP"
fi

# Check Kernel API Headers
HDRS_STAMP="${STAMPS_DIR}/.stamp.stage0_kernel_headers"
if [ ! -f "$HDRS_STAMP" ]; then
  printf '[STAGE0] Installing Kernel API headers into %s/%s/include
' "$HOST_ROOT" "$LIBSCRIPT_TARGET_TRIPLET"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${HDRS_STAMP}.tmp"
  mv "${HDRS_STAMP}.tmp" "$HDRS_STAMP"
fi

# Check Target C Library
LIBC_STAMP="${STAMPS_DIR}/.stamp.stage0_target_libc"
if [ ! -f "$LIBC_STAMP" ]; then
  printf '[STAGE0] Compiling Target C Library (%s) for %s
' "$TARGET_LIBC" "$LIBSCRIPT_TARGET_TRIPLET"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${LIBC_STAMP}.tmp"
  mv "${LIBC_STAMP}.tmp" "$LIBC_STAMP"
fi

# Check GCC Pass 2
GCC2_STAMP="${STAMPS_DIR}/.stamp.stage0_gcc_pass2"
if [ ! -f "$GCC2_STAMP" ]; then
  printf '[STAGE0] Building Full Cross-GCC Pass 2 for %s
' "$LIBSCRIPT_TARGET_TRIPLET"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${GCC2_STAMP}.tmp"
  mv "${GCC2_STAMP}.tmp" "$GCC2_STAMP"
fi

# Atomically record Stage 0 completion
date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAGE0_STAMP}.tmp"
mv "${STAGE0_STAMP}.tmp" "$STAGE0_STAMP"
printf '[OK]    Stage 0 Cross-Toolchain bootstrap finished: %s
' "$STAGE0_STAMP"
