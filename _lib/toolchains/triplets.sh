#!/bin/sh
# ## Overview
# Standard cross-toolchain triplet and compiler security flags definitions.
# Exports canonical target triplets, security hardening flags, and SOURCE_DATE_EPOCH.
#
# ## Usage
# Sourced or executed to export triplet variables:
#   . ./_lib/toolchains/triplets.sh [target_arch] [target_libc] [target_os]

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

export LIBSCRIPT_TARGET_TRIPLET
export LIBSCRIPT_SECURITY_CFLAGS
export LIBSCRIPT_SECURITY_LDFLAGS
export SOURCE_DATE_EPOCH

if [ "${4:-}" != "--quiet" ]; then
  printf '[INFO] Triplet: %s
' "$LIBSCRIPT_TARGET_TRIPLET"
  printf '[INFO] CFLAGS:  %s
' "$LIBSCRIPT_SECURITY_CFLAGS"
fi
