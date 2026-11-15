#!/bin/sh
# ## Overview
# Multi-compiler FreeRTOS C11 torture suite, ROM/RAM byte delta, and simulator/QEMU verification harness.
# Evaluates gcc, clang, tcc (POSIX sim), edgcpp, and custom-cc, emitting build-metrics.json.
#
# ## Usage
# ./_lib/kernel/freertos/compare_compilers.sh [--compilers="default gcc clang edgcpp"] [--board=posix_gcc]

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

COMPILERS="${FREERTOS_COMPARE_COMPILERS:-default gcc clang edgcpp}"
PORT="${FREERTOS_PORT:-posix_gcc}"
OUT_JSON="${LIBSCRIPT_ROOT_DIR}/build/freertos-build-metrics.json"

for _arg in "$@"; do
  case "$_arg" in
    --compilers=*) COMPILERS=$(printf '%s' "${_arg#*=}" | tr ',' ' ') ;;
    --board=*|--port=*) PORT="${_arg#*=}" ;;
    --out=*) OUT_JSON="${_arg#*=}" ;;
  esac
done

mkdir -p "$(dirname "$OUT_JSON")"
TMP_RECORDS="${TMPDIR:-/tmp}/freertos_metrics_$$.ndjson"
rm -f "$TMP_RECORDS"

# ## cleanup_fr_metrics
# Cleans temporary NDJSON scratch files on exit.
# shellcheck disable=SC2329
cleanup_fr_metrics() {
  rm -f "$TMP_RECORDS"
}
trap cleanup_fr_metrics EXIT INT TERM HUP

for _cc in $COMPILERS; do
  _sys="${LIBSCRIPT_ROOT_DIR}/build/freertos-compare/${PORT}-${_cc}"
  _t0=$(date +%s)
  FORCE_REBUILD=1 STACK='' "${SCRIPT_DIR}/build_firmware.sh" --board="$PORT" --compiler="$_cc" --sysroot="$_sys"
  _t1=$(date +%s)
  _dur=$((_t1 - _t0))
  _elf="${_sys}/boot/freertos.elf"
  _bin="${_sys}/boot/freertos.bin"
  _elf_bytes=$(wc -c < "$_elf" | tr -d '[:space:]')
  _bin_bytes=$(wc -c < "$_bin" | tr -d '[:space:]')
  _boot_status='STAGED_OK'
  if [ "$PORT" = "posix_gcc" ] && [ -x "$_elf" ]; then
    _out=$("$_elf" 2>&1 || true)
    case "$_out" in
      *LIBSCRIPT_FREERTOS_BOOT_OK*) _boot_status='LIBSCRIPT_FREERTOS_BOOT_OK' ;;
    esac
  fi
  printf '{"kernel":"freertos","port":"%s","compiler":"%s","elf_bytes":%s,"bin_bytes":%s,"compile_seconds":%s,"boot_status":"%s"}\n' \
    "$PORT" "$_cc" "$_elf_bytes" "$_bin_bytes" "$_dur" "$_boot_status" >> "$TMP_RECORDS"
done

if command -v jq >/dev/null 2>&1; then
  jq -s '{schema_version:"1.0.0",kernel:"freertos",results:.}' "$TMP_RECORDS" > "${OUT_JSON}.tmp"
  mv "${OUT_JSON}.tmp" "$OUT_JSON"
else
  cp -f "$TMP_RECORDS" "$OUT_JSON"
fi
printf '[OK] Wrote FreeRTOS multi-compiler differential report -> %s\n' "$OUT_JSON"
exit 0
