#!/bin/sh
# ## Overview
# Codifies the standard context contract variables and idempotency stamp
# protocols passed between Tier 2 synthesizers and Tier 1 leaf recipes.
#
# ## Usage
# Source this file to initialize and validate standard context variables:
#   . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/context.sh"
#   libscript_context_validate

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

# Standard Context Contract Defaults
: "${LIBSCRIPT_BUILD_DIR:=${TMPDIR:-/tmp}/libscript_build}"
: "${LIBSCRIPT_TARGET_SYSROOT:=${LIBSCRIPT_BUILD_DIR}/sysroot}"
: "${LIBSCRIPT_HOST_ROOT:=/tools}"
: "${LIBSCRIPT_STAGE:=stage0}"
: "${LIBSCRIPT_OFFLINE:=0}"
: "${LIBSCRIPT_CACHE_DIR:=${LIBSCRIPT_ROOT_DIR}/cache}"

# Architecture auto-detection
if [ -z "${LIBSCRIPT_TARGET_ARCH:-}" ]; then
  _raw_arch=$(uname -m 2>/dev/null || printf '%s' "x86_64")
  case "$_raw_arch" in
    x86_64|amd64) LIBSCRIPT_TARGET_ARCH="x86_64" ;;
    aarch64|arm64) LIBSCRIPT_TARGET_ARCH="aarch64" ;;
    riscv64) LIBSCRIPT_TARGET_ARCH="riscv64" ;;
    armv7*|armhf) LIBSCRIPT_TARGET_ARCH="armv7l" ;;
    i*86|x86) LIBSCRIPT_TARGET_ARCH="i686" ;;
    *) LIBSCRIPT_TARGET_ARCH="$_raw_arch" ;;
  esac
fi

# Operating system auto-detection
if [ -z "${LIBSCRIPT_TARGET_OS:-}" ]; then
  _raw_os=$(uname -s 2>/dev/null || printf '%s' "Linux")
  case "$_raw_os" in
    Linux) LIBSCRIPT_TARGET_OS="linux" ;;
    FreeBSD) LIBSCRIPT_TARGET_OS="freebsd" ;;
    *) LIBSCRIPT_TARGET_OS="linux" ;;
  esac
fi

# C runtime library default
: "${LIBSCRIPT_TARGET_LIBC:=glibc}"

export LIBSCRIPT_BUILD_DIR
export LIBSCRIPT_TARGET_SYSROOT
export LIBSCRIPT_HOST_ROOT
export LIBSCRIPT_STAGE
export LIBSCRIPT_TARGET_ARCH
export LIBSCRIPT_TARGET_LIBC
export LIBSCRIPT_TARGET_OS
export LIBSCRIPT_OFFLINE
export LIBSCRIPT_CACHE_DIR

# Deterministic stamp directory
LIBSCRIPT_STAMP_DIR="${LIBSCRIPT_TARGET_SYSROOT}/var/lib/libscript/stamps"
export LIBSCRIPT_STAMP_DIR

# ## libscript_stamp_path
# Returns the absolute path for a given step's stamp file.
libscript_stamp_path() {
  _step_name="${1:-}"
  if [ -z "$_step_name" ]; then
    printf '[ERROR] Step name required for stamp resolution.
' >&2
    return 1
  fi
  printf '%s/.stamp.%s
' "${LIBSCRIPT_STAMP_DIR}" "${_step_name}"
}

# ## libscript_stamp_check
# Checks if a step has already been marked completed.
libscript_stamp_check() {
  _step_name="${1:-}"
  _stamp_file=$(libscript_stamp_path "$_step_name")
  if [ -f "$_stamp_file" ]; then
    return 0
  fi
  return 1
}

# ## libscript_stamp_mark
# Atomically marks a step as completed by writing its stamp file.
libscript_stamp_mark() {
  _step_name="${1:-}"
  _stamp_file=$(libscript_stamp_path "$_step_name")
  _stamp_dir="${_stamp_file%/*}"
  if [ ! -d "$_stamp_dir" ]; then
    mkdir -p "$_stamp_dir"
  fi
  touch "$_stamp_file"
}

# ## libscript_context_validate
# Validates that all required context variables meet architectural contracts.
libscript_context_validate() {
  case "$LIBSCRIPT_STAGE" in
    stage0|stage1|stage2|target-userland|runtime) ;;
    *)
      printf '[ERROR] Invalid LIBSCRIPT_STAGE: %s
' "$LIBSCRIPT_STAGE" >&2
      return 1
      ;;
  esac

  case "$LIBSCRIPT_TARGET_ARCH" in
    x86_64|aarch64|riscv64|armv7l|i686) ;;
    *)
      printf '[ERROR] Invalid LIBSCRIPT_TARGET_ARCH: %s
' "$LIBSCRIPT_TARGET_ARCH" >&2
      return 1
      ;;
  esac

  case "$LIBSCRIPT_TARGET_LIBC" in
    glibc|musl|bsd-libc|nolibc) ;;
    *)
      printf '[ERROR] Invalid LIBSCRIPT_TARGET_LIBC: %s
' "$LIBSCRIPT_TARGET_LIBC" >&2
      return 1
      ;;
  esac

  case "$LIBSCRIPT_TARGET_OS" in
    linux|freebsd|unikraft) ;;
    *)
      printf '[ERROR] Invalid LIBSCRIPT_TARGET_OS: %s
' "$LIBSCRIPT_TARGET_OS" >&2
      return 1
      ;;
  esac

  case "$LIBSCRIPT_OFFLINE" in
    0|1) ;;
    *)
      printf '[ERROR] Invalid LIBSCRIPT_OFFLINE: %s (must be 0 or 1)
' "$LIBSCRIPT_OFFLINE" >&2
      return 1
      ;;
  esac

  return 0
}
