#!/bin/sh
# ## Overview
# Cryptographically signs and pads Zephyr or FreeRTOS raw firmware binaries into MCUboot v2 A/B slot images.
#
# ## Usage
# ./_lib/bootloaders/mcuboot/sign_firmware.sh <in.bin> <out.signed.bin> [--key=<pem>] [--slot-size=0x40000] [--header-size=0x200]

set -feu

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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

IN_BIN=''
OUT_BIN=''
KEY_FILE="${MCUBOOT_KEY_FILE:-}"
KEY_TYPE="${MCUBOOT_KEY_TYPE:-rsa-2048}"
SLOT_SIZE="${MCUBOOT_SLOT_SIZE:-0x40000}"
HEADER_SIZE="${MCUBOOT_HEADER_SIZE:-0x200}"

while [ $# -gt 0 ]; do
  case "$1" in
    --key=*) KEY_FILE="${1#*=}"; shift ;;
    --key-type=*) KEY_TYPE="${1#*=}"; shift ;;
    --slot-size=*) SLOT_SIZE="${1#*=}"; shift ;;
    --header-size=*) HEADER_SIZE="${1#*=}"; shift ;;
    *)
      if [ -z "$IN_BIN" ]; then
        IN_BIN="$1"
      else
        OUT_BIN="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$IN_BIN" ] && [ -n "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
  for _cand in \
    "${LIBSCRIPT_TARGET_SYSROOT}/boot/zephyr.bin" \
    "${LIBSCRIPT_TARGET_SYSROOT}/boot/freertos.bin" \
    "${LIBSCRIPT_TARGET_SYSROOT}/boot/firmware.bin"; do
    if [ -s "$_cand" ]; then
      IN_BIN="$_cand"
      break
    fi
  done
  if [ -n "$IN_BIN" ] && [ -z "$OUT_BIN" ]; then
    OUT_BIN="${LIBSCRIPT_TARGET_SYSROOT}/boot/firmware.mcuboot.signed.bin"
  fi
fi

if [ -z "$IN_BIN" ] || [ ! -f "$IN_BIN" ]; then
  if [ "${LIBSCRIPT_ALLOW_STUB:-0}" = "1" ] && [ -n "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/boot"
    IN_BIN="${LIBSCRIPT_TARGET_SYSROOT}/boot/firmware.raw.bin"
    printf 'LIBSCRIPT_RTOS_RAW_PAYLOAD\n' > "$IN_BIN"
    [ -n "$OUT_BIN" ] || OUT_BIN="${LIBSCRIPT_TARGET_SYSROOT}/boot/firmware.mcuboot.signed.bin"
  else
    printf '[ERROR] sign_firmware.sh requires an existing input firmware binary.\n' >&2
    exit 1
  fi
fi
[ -n "$OUT_BIN" ] || OUT_BIN="${IN_BIN}.signed.bin"
mkdir -p "$(dirname "$OUT_BIN")"

# ## ensure_c_signer
# Compiles the zero-dependency C11 MCUboot v2 slot signer when upstream imgtool is absent.
ensure_c_signer() {
  _bin_cache="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot/bin"
  mkdir -p "$_bin_cache"
  _signer="${_bin_cache}/mcuboot_c_signer"
  if [ -x "$_signer" ]; then
    printf '%s\n' "$_signer"
    return 0
  fi
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "${_signer}.tmp" "${SCRIPT_DIR}/mcuboot_c_signer.c" 2>/dev/null; then
        mv "${_signer}.tmp" "$_signer"
        printf '%s\n' "$_signer"
        return 0
      fi
    fi
  done
  return 1
}

if command -v imgtool >/dev/null 2>&1; then
  if [ -z "$KEY_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    _sec_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot/keys"
    mkdir -p "$_sec_dir"
    KEY_FILE="${_sec_dir}/mcuboot-${KEY_TYPE}.pem"
    if [ ! -f "$KEY_FILE" ]; then
      imgtool keygen -k "$KEY_FILE" -t "$KEY_TYPE" >/dev/null 2>&1 || true
    fi
  fi
  if [ -f "$KEY_FILE" ]; then
    imgtool sign \
      --key "$KEY_FILE" \
      --header-size "$HEADER_SIZE" \
      --align 4 \
      --version "1.0.0" \
      --slot-size "$SLOT_SIZE" \
      --pad \
      --confirm \
      "$IN_BIN" "${OUT_BIN}.tmp"
    mv "${OUT_BIN}.tmp" "$OUT_BIN"
    printf '[OK] Signed MCUboot image via imgtool (%s) -> %s\n' "$KEY_TYPE" "$OUT_BIN"
    exit 0
  fi
fi

_c_signer=$(ensure_c_signer || true)
if [ -n "$_c_signer" ] && [ -x "$_c_signer" ]; then
  "$_c_signer" "$IN_BIN" "${OUT_BIN}.tmp" "$HEADER_SIZE" "$SLOT_SIZE"
  mv "${OUT_BIN}.tmp" "$OUT_BIN"
  printf '[OK] Signed MCUboot v2 slot image via C11 signer -> %s\n' "$OUT_BIN"
  exit 0
fi

printf '[ERROR] Neither imgtool nor a C11 compiler for mcuboot_c_signer.c was found.\n' >&2
exit 1
