#!/bin/sh
# ## Overview
# Standard cross-toolchain triplet and compiler security flags definitions.
# Exports canonical target triplets, security hardening flags, and SOURCE_DATE_EPOCH.
# ## Usage
# Sourced or executed to export triplet variables:
#   . ./engine/target/triplets.sh [target_arch] [target_libc] [target_os]
set -feu
_triplets_caller_this="${THIS_FILE:-}"; _triplets_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_triplets_caller_this" ] && THIS_FILE="$_triplets_caller_this"
    [ -n "$_triplets_caller_dir" ] && SCRIPT_DIR="$_triplets_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TARGET_ARCH="${1:-${LIBSCRIPT_TARGET_ARCH:-x86_64}}"
TARGET_LIBC="${2:-${LIBSCRIPT_TARGET_LIBC:-glibc}}"
TARGET_OS="${3:-${LIBSCRIPT_TARGET_OS:-linux}}"
RTOS_BOARD="${LIBSCRIPT_RTOS_BOARD:-}"

case "$RTOS_BOARD" in
  native_sim*|posix_gcc|win32_sim|msvc_ming_win32)
    _host_m=$(uname -m 2>/dev/null || printf 'x86_64')
    _host_s=$(uname -s 2>/dev/null || printf 'Linux')
    case "$_host_s" in
      Darwin*) LIBSCRIPT_TARGET_TRIPLET="${_host_m}-apple-darwin" ;;
      FreeBSD*) LIBSCRIPT_TARGET_TRIPLET="${_host_m}-unknown-freebsd" ;;
      MINGW*|MSYS*|CYGWIN*|Windows_NT) LIBSCRIPT_TARGET_TRIPLET="${_host_m}-pc-windows-gnu" ;;
      *) LIBSCRIPT_TARGET_TRIPLET="${_host_m}-pc-linux-gnu" ;;
    esac
    _IS_FREESTANDING=0
    ;;
  *)
    _IS_FREESTANDING=0
    case "$TARGET_OS" in
      zephyr*|rtos-zephyr)
        _IS_FREESTANDING=1
        case "$TARGET_ARCH" in
          arm|armv7m|armv8m|armv7l) LIBSCRIPT_TARGET_TRIPLET='arm-zephyr-eabi' ;;
          aarch64|arm64) LIBSCRIPT_TARGET_TRIPLET='aarch64-zephyr-elf' ;;
          riscv32) LIBSCRIPT_TARGET_TRIPLET='riscv32-zephyr-elf' ;;
          riscv64) LIBSCRIPT_TARGET_TRIPLET='riscv64-zephyr-elf' ;;
          xtensa) LIBSCRIPT_TARGET_TRIPLET='xtensa-zephyr-elf' ;;
          x86_64|amd64|i686|*) LIBSCRIPT_TARGET_TRIPLET='x86_64-zephyr-elf' ;;
        esac
        ;;
      freertos*|rtos-freertos)
        _IS_FREESTANDING=1
        case "$TARGET_ARCH" in
          arm|armv7m|armv8m|armv7l) LIBSCRIPT_TARGET_TRIPLET='arm-none-eabi' ;;
          aarch64|arm64) LIBSCRIPT_TARGET_TRIPLET='aarch64-none-elf' ;;
          riscv32) LIBSCRIPT_TARGET_TRIPLET='riscv32-unknown-elf' ;;
          riscv64) LIBSCRIPT_TARGET_TRIPLET='riscv64-unknown-elf' ;;
          x86_64|amd64|i686|*) LIBSCRIPT_TARGET_TRIPLET='x86_64-unknown-elf' ;;
        esac
        ;;
      freebsd*)
        LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-unknown-freebsd14.0"
        ;;
      reactos*)
        case "$TARGET_ARCH" in
          i686|i386|x86) LIBSCRIPT_TARGET_TRIPLET='i686-w64-mingw32' ;;
          x86_64|amd64) LIBSCRIPT_TARGET_TRIPLET='x86_64-w64-mingw32' ;;
          *) LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-w64-mingw32" ;;
        esac
        ;;
      unikraft*)
        LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-unikraft-elf"
        ;;
      linux*)
        case "$TARGET_LIBC" in
          musl)
            LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-libscript-linux-musl"
            ;;
          glibc|*)
            LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-libscript-linux-gnu"
            ;;
        esac
        ;;
      *)
        LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-libscript-${TARGET_OS}-gnu"
        ;;
    esac
    ;;
esac

case "$TARGET_LIBC" in
  newlib|picolibc|nolibc|zephyr-minimal|freertos-none)
    _IS_FREESTANDING=1
    ;;
esac

# Standard reproducible and security compiler flags
if [ "$_IS_FREESTANDING" = "1" ]; then
  LIBSCRIPT_SECURITY_CFLAGS='-fno-common -ffreestanding -fdata-sections -ffunction-sections'
  LIBSCRIPT_SECURITY_LDFLAGS='-Wl,--gc-sections'
elif [ "$TARGET_OS" = 'reactos' ]; then
  LIBSCRIPT_SECURITY_CFLAGS='-O2 -pipe -fno-common -D_FORTIFY_SOURCE=2'
  case "$TARGET_ARCH" in
    x86_64|amd64) LIBSCRIPT_SECURITY_LDFLAGS='-Wl,--nxcompat -Wl,--dynamicbase -Wl,--high-entropy-va' ;;
    *) LIBSCRIPT_SECURITY_LDFLAGS='-Wl,--nxcompat -Wl,--dynamicbase' ;;
  esac
else
  LIBSCRIPT_SECURITY_CFLAGS="-fno-common -fPIC -fstack-protector-strong -D_FORTIFY_SOURCE=2"
  LIBSCRIPT_SECURITY_LDFLAGS="-Wl,-z,relro -Wl,-z,now"
fi
: "${SOURCE_DATE_EPOCH:=1700000000}"

# ## resolve_compiler_flags
# Resolves compiler-specific security and optimization flags, omitting GNU-only hardening flags for minimal compilers such as tcc and custom-cc.
resolve_compiler_flags() {
  _cc_id="${1:-${CC_BACKEND:-default}}"
  case "${_cc_id}" in
    tcc|custom-cc|edgcpp|edgcpp*|msvc)
      LIBSCRIPT_COMPILER_CFLAGS='-O2'
      LIBSCRIPT_COMPILER_LDFLAGS=""
      ;;
    clang)
      LIBSCRIPT_COMPILER_CFLAGS="${LIBSCRIPT_SECURITY_CFLAGS} -O2"
      LIBSCRIPT_COMPILER_LDFLAGS="${LIBSCRIPT_SECURITY_LDFLAGS}"
      ;;
    gcc|default|*)
      LIBSCRIPT_COMPILER_CFLAGS="${LIBSCRIPT_SECURITY_CFLAGS} -O2"
      LIBSCRIPT_COMPILER_LDFLAGS="${LIBSCRIPT_SECURITY_LDFLAGS}"
      ;;
  esac
  export LIBSCRIPT_COMPILER_CFLAGS
  export LIBSCRIPT_COMPILER_LDFLAGS
}

resolve_compiler_flags "${CC_BACKEND:-default}"

export LIBSCRIPT_TARGET_TRIPLET
export LIBSCRIPT_SECURITY_CFLAGS
export LIBSCRIPT_SECURITY_LDFLAGS
export SOURCE_DATE_EPOCH

if [ "${4:-}" != "--quiet" ] && [ "${LIBSCRIPT_TRIPLETS_QUIET:-0}" != "1" ]; then
  printf '[INFO] Triplet: %s\n' "$LIBSCRIPT_TARGET_TRIPLET"
  printf '[INFO] CFLAGS:  %s\n' "$LIBSCRIPT_SECURITY_CFLAGS"
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_triplets_caller_dir:-}" ] && SCRIPT_DIR="$_triplets_caller_dir"
[ -n "${_triplets_caller_this:-}" ] && THIS_FILE="$_triplets_caller_this"
unset SCRIPT_NAME _triplets_caller_this _triplets_caller_dir || true
