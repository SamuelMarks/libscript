#!/bin/sh
# ## Overview
# Standard cross-toolchain triplet and compiler security flags definitions.
# Exports canonical target triplets, security hardening flags, and SOURCE_DATE_EPOCH.
#
# ## Usage
# Sourced or executed to export triplet variables:
#   . ./_lib/toolchains/triplets.sh [target_arch] [target_libc] [target_os]

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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TARGET_ARCH="${1:-${LIBSCRIPT_TARGET_ARCH:-x86_64}}"
TARGET_LIBC="${2:-${LIBSCRIPT_TARGET_LIBC:-glibc}}"
TARGET_OS="${3:-${LIBSCRIPT_TARGET_OS:-linux}}"

case "$TARGET_OS" in
  freebsd*)
    LIBSCRIPT_TARGET_TRIPLET="${TARGET_ARCH}-unknown-freebsd14.0"
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

# Standard reproducible and security compiler flags
LIBSCRIPT_SECURITY_CFLAGS="-fno-common -fPIC -fstack-protector-strong -D_FORTIFY_SOURCE=2"
LIBSCRIPT_SECURITY_LDFLAGS="-Wl,-z,relro -Wl,-z,now"
: "${SOURCE_DATE_EPOCH:=1700000000}"

# ## resolve_compiler_flags
# Resolves compiler-specific security and optimization flags, omitting GNU-only hardening flags for minimal compilers such as tcc and custom-cc.
resolve_compiler_flags() {
  _cc_id="${1:-${CC_BACKEND:-default}}"
  case "${_cc_id}" in
    tcc|custom-cc|edgcpp)
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
unset _triplets_caller_this _triplets_caller_dir || true
