#!/bin/sh
# ## Overview
# Recipe for PulseAudio: Networked sound server daemon.
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
STAMP_FILE="${STAMPS_DIR}/.stamp.pulseaudio"

if [ ! -d "$STAMPS_DIR" ]; then
  mkdir -p "$STAMPS_DIR"
fi

if ! command -v pulseaudio >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apk add --no-cache pulseaudio || true
  elif command -v apt-get >/dev/null 2>&1; then
    if ! command -v priv >/dev/null 2>&1; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
    priv apt-get update -qq || true
    priv apt-get install -y pulseaudio || true
  fi
fi

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]  %s already installed (%s)
' "pulseaudio" "$STAMP_FILE"
  exit 0
fi

printf '[RECIPE] Staging %s into %s (action: %s)
' "PulseAudio" "$TARGET_SYSROOT" "$ACTION"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]    %s staged successfully: %s
' "pulseaudio" "$STAMP_FILE"
