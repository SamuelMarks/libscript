#!/bin/sh
# ## Overview
# Unified CLI entrypoint to synthesize and package a Zephyr or FreeRTOS profile into
# firmware-bin, firmware-elf, firmware-hex, firmware-uf2, mcuboot-signed, renode-resc, or direct-kernel bundles.
#
# ## Usage
# synthesis/formats/rtos_distro.sh [--format <firmware-bin|firmware-elf|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc|direct-kernel>] --profile <profile_json> [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]

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

FORMAT="${LIBSCRIPT_RTOS_DEFAULT_FORMAT:-}"
PROFILE="${LIBSCRIPT_RTOS_DEFAULT_PROFILE:-${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/rtos/zephyr-qemu-x86_64-minimal.json}"
OUTPUT=''
BOARD_OVERRIDE=''
MCUBOOT_KEY_OVERRIDE=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
STRICT_BUILD="${LIBSCRIPT_STRICT_IMAGE_BUILD:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"
OFFLINE_MODE="${LIBSCRIPT_OFFLINE:-0}"

# ## show_help
# Displays usage instructions for rtos_distro.sh.
show_help() {
  printf 'Usage: %s [--format <firmware-bin|firmware-elf|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc|direct-kernel>] [--profile <path|preset>] [--board <board>] [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]\n' "$THIS_FILE"
}

# ## resolve_profile_path
# Resolves a file path or shorthand RTOS preset name under synthesis/profiles/ to an existing JSON file.
resolve_profile_path() {
  _rp_in="$1"
  if [ -f "$_rp_in" ]; then
    printf '%s\n' "$_rp_in"
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_rp_in}.json" ]; then
    printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/${_rp_in}.json"
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/rtos/${_rp_in}.json" ]; then
    printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/rtos/${_rp_in}.json"
    return 0
  fi
  printf '%s\n' "$_rp_in"
  return 0
}

# ## ensure_jq_ready
# Ensures jq is available on PATH or bootstrapped from _lib/utilities/jq.
ensure_jq_ready() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    _ej_this="${THIS_FILE}"
    _ej_dir="${SCRIPT_DIR}"
    _ej_stack="${STACK}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="${_ej_this}"
    SCRIPT_DIR="${_ej_dir}"
    STACK="${_ej_stack}"
    export STACK
  fi
  command -v jq >/dev/null 2>&1
}

# ## compute_profile_hash
# Computes a deterministic SHA-256 or byte-length fingerprint for a profile file.
compute_profile_hash() {
  _cph_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$_cph_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$_cph_file" | awk '{print $1}'
  else
    wc -c < "$_cph_file" | tr -d ' '
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --board) BOARD_OVERRIDE="$2"; shift 2 ;;
    --board=*) BOARD_OVERRIDE="${1#*=}"; shift ;;
    --key-type) MCUBOOT_KEY_OVERRIDE="$2"; shift 2 ;;
    --key-type=*) MCUBOOT_KEY_OVERRIDE="${1#*=}"; shift ;;
    --output|-o|--out) OUTPUT="$2"; shift 2 ;;
    --output=*|--out=*) OUTPUT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --strict) STRICT_BUILD='1'; ALLOW_STUB='0'; shift ;;
    --allow-stub) ALLOW_STUB='1'; STRICT_BUILD='0'; shift ;;
    --offline) OFFLINE_MODE='1'; shift ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

PROFILE=$(resolve_profile_path "$PROFILE")
if [ ! -f "$PROFILE" ]; then
  printf '[ERROR] RTOS profile not found: %s\n' "$PROFILE" >&2
  exit 1
fi

PBASE="${PROFILE##*/}"
PNAME="${PBASE%.json}"

KERNEL_ARG='rtos-zephyr'
BOARD='qemu_x86_64'
MCUBOOT_FLAG='0'
KEY_TYPE_VAL="${MCUBOOT_KEY_TYPE:-rsa-2048}"
HEAP_IMPL_VAL="${FREERTOS_HEAP_IMPL:-}"

if ensure_jq_ready; then
  _os_fam=$(jq -r '.target.os_family // .target.os // ""' "$PROFILE" 2>/dev/null || true)
  case "$_os_fam" in
    *freertos*) KERNEL_ARG='rtos-freertos'; BOARD='posix_gcc' ;;
    *zephyr*) KERNEL_ARG='rtos-zephyr'; BOARD='qemu_x86_64' ;;
  esac
  _prof_board=$(jq -r '.rtos.board // ""' "$PROFILE" 2>/dev/null || true)
  [ -n "$_prof_board" ] && BOARD="$_prof_board"
  _prof_mcu=$(jq -r 'if .rtos.mcuboot.enabled == true then "1" else "0" end' "$PROFILE" 2>/dev/null || printf '0')
  MCUBOOT_FLAG="$_prof_mcu"
  _prof_ktype=$(jq -r '.rtos.mcuboot.signing_key_type // ""' "$PROFILE" 2>/dev/null || true)
  [ -n "$_prof_ktype" ] && KEY_TYPE_VAL="$_prof_ktype"
  _prof_heap=$(jq -r '.rtos.heap_implementation // ""' "$PROFILE" 2>/dev/null || true)
  [ -n "$_prof_heap" ] && HEAP_IMPL_VAL="$_prof_heap"
  if [ -z "$FORMAT" ]; then
    FORMAT=$(jq -r '.output_formats[0] // ""' "$PROFILE" 2>/dev/null || true)
  fi
fi

[ -n "$BOARD_OVERRIDE" ] && BOARD="$BOARD_OVERRIDE"
[ -n "$MCUBOOT_KEY_OVERRIDE" ] && KEY_TYPE_VAL="$MCUBOOT_KEY_OVERRIDE"
export MCUBOOT_KEY_TYPE="$KEY_TYPE_VAL"
if [ -n "$HEAP_IMPL_VAL" ]; then
  export FREERTOS_HEAP_IMPL="$HEAP_IMPL_VAL"
fi
[ -n "$FORMAT" ] || FORMAT='firmware-bin'

case "$FORMAT" in
  bin) FORMAT='firmware-bin' ;;
  elf) FORMAT='firmware-elf' ;;
  hex) FORMAT='firmware-hex' ;;
  uf2) FORMAT='firmware-uf2' ;;
esac

case "$FORMAT" in
  firmware-bin)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.bin}"
    ;;
  firmware-elf)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.elf}"
    ;;
  firmware-hex)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.hex}"
    ;;
  firmware-uf2)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.uf2}"
    ;;
  mcuboot-signed)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.signed.bin}"
    MCUBOOT_FLAG='1'
    ;;
  renode-resc)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${PNAME}-${BOARD}.resc}"
    ;;
  direct-kernel)
    : "${OUTPUT:=${LIBSCRIPT_ROOT_DIR}/build/images/direct-kernel/${PNAME}-${BOARD}}"
    ;;
  *)
    printf '[ERROR] Unsupported RTOS packaging format: %s\n' "$FORMAT" >&2
    printf 'Supported formats: firmware-bin, firmware-elf, firmware-hex, firmware-uf2, mcuboot-signed, renode-resc, direct-kernel\n' >&2
    exit 1
    ;;
esac

EXTRA_SYNTH_ARGS="--board=${BOARD}"
[ "$MCUBOOT_FLAG" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --mcuboot"
[ "$STRICT_BUILD" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --strict"
[ "$ALLOW_STUB" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --allow-stub"
[ "$OFFLINE_MODE" = '1' ] && EXTRA_SYNTH_ARGS="${EXTRA_SYNTH_ARGS} --offline"

if [ "$DRY_RUN" = '1' ]; then
  printf '[DISTRO]   Validating RTOS (%s, board=%s) synthesis plan from %s (format=%s)...\n' "$KERNEL_ARG" "$BOARD" "$PROFILE" "$FORMAT"
  # shellcheck disable=SC2086
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
    --kernel="$KERNEL_ARG" \
    --profile="$PROFILE" \
    --format="$FORMAT" \
    --out="$OUTPUT" \
    $EXTRA_SYNTH_ARGS \
    --dry-run
  printf '[OK]       RTOS dry-run plan verified (%s): %s\n' "$FORMAT" "$OUTPUT"
  exit 0
fi

STAMP_FILE="${OUTPUT}.distro.stamp"
PROF_HASH=$(compute_profile_hash "$PROFILE")

if [ -f "$STAMP_FILE" ] && { [ -f "$OUTPUT" ] || [ -d "$OUTPUT" ]; }; then
  if grep -q "^profile_hash=${PROF_HASH}$" "$STAMP_FILE" 2>/dev/null && grep -q "^format=${FORMAT}$" "$STAMP_FILE" 2>/dev/null && grep -q "^key_type=${KEY_TYPE_VAL}$" "$STAMP_FILE" 2>/dev/null; then
    printf '[SKIP]     RTOS firmware artifact already synthesized: %s\n' "$OUTPUT"
    exit 0
  fi
fi

mkdir -p "$(dirname "$OUTPUT")"

printf '[DISTRO]   Synthesizing RTOS (%s, board=%s) artifact from %s...\n' "$KERNEL_ARG" "$BOARD" "$PROFILE"
# shellcheck disable=SC2086
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/synthesize-image.sh" \
  --kernel="$KERNEL_ARG" \
  --profile="$PROFILE" \
  --format="$FORMAT" \
  --out="$OUTPUT" \
  $EXTRA_SYNTH_ARGS

printf 'format=%s\nkernel=%s\nboard=%s\nkey_type=%s\nprofile=%s\nprofile_hash=%s\ntimestamp=%s\n' \
  "$FORMAT" "$KERNEL_ARG" "$BOARD" "$KEY_TYPE_VAL" "$PROFILE" "$PROF_HASH" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"

printf '[OK]       RTOS firmware packaged as %s: %s\n' "$FORMAT" "$OUTPUT"
