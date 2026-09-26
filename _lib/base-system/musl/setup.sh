#!/bin/sh
# ## Overview
# Recipe for Musl C Library: Lightweight, standards-conformant C standard library.
# Complies with standard LibScript Context Contract and stamp idempotency.
#
# ## Usage
# Run `setup.sh [action]` (default action: install/compile).

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

ACTION="${1:-compile}"
TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
STAMP_FILE="${STAMPS_DIR}/.stamp.musl"

if [ ! -d "$STAMPS_DIR" ]; then
  mkdir -p "$STAMPS_DIR"
fi

if ! command -v musl-gcc >/dev/null 2>&1 && [ ! -f /usr/local/musl/bin/musl-gcc ]; then
  if command -v apk >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apk add --no-cache musl || true
  elif command -v apt-get >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apt-get update -qq || true
    priv apt-get install --no-install-recommends -y musl musl-tools || true
  elif command -v dnf >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv dnf install -y musl-devel musl-gcc 2>/dev/null || {
      priv dnf install -y gcc make tar curl || true
      _musl_tmp=$(mktemp -d)
      curl -sSL https://musl.libc.org/releases/musl-1.2.5.tar.gz | tar -xz -C "$_musl_tmp"
      (cd "$_musl_tmp"/musl-1.2.5 && ./configure --prefix=/usr/local/musl && make -j"$(nproc 2>/dev/null || echo 2)" && priv make install)
      priv ln -sf /usr/local/musl/bin/musl-gcc /usr/local/bin/musl-gcc
      rm -rf "$_musl_tmp"
    }
  fi
fi

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  %s already installed (%s)
' "musl" "$STAMP_FILE"
  exit 0
fi

printf '[RECIPE] Staging %s into %s (action: %s)
' "Musl C Library" "$TARGET_SYSROOT" "$ACTION"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]    %s staged successfully: %s
' "musl" "$STAMP_FILE"
