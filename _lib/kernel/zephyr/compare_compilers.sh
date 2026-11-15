#!/bin/sh
# ## Overview
# Multi-compiler Zephyr RTOS ELF size, symbol count, and QEMU/native_sim boot verification harness.
# Compiles Zephyr firmware across default, gcc, clang, edgcpp, and custom-cc and writes build-metrics.json.
#
# ## Usage
# ./_lib/kernel/zephyr/compare_compilers.sh [--compilers="default gcc clang edgcpp"] [--board=qemu_x86_64]

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

COMPILERS="${ZEPHYR_COMPARE_COMPILERS:-default gcc clang edgcpp}"
BOARD="${ZEPHYR_BOARD:-qemu_x86_64}"
OUT_JSON="${LIBSCRIPT_ROOT_DIR}/build/zephyr-build-metrics.json"

for _arg in "$@"; do
  case "$_arg" in
    --compilers=*) COMPILERS=$(printf '%s' "${_arg#*=}" | tr ',' ' ') ;;
    --board=*) BOARD="${_arg#*=}" ;;
    --out=*) OUT_JSON="${_arg#*=}" ;;
  esac
done

mkdir -p "$(dirname "$OUT_JSON")"
TMP_RECORDS="${TMPDIR:-/tmp}/zephyr_metrics_$$.ndjson"
rm -f "$TMP_RECORDS"

# ## cleanup_metrics
# Cleans temporary NDJSON scratch files on exit.
# shellcheck disable=SC2329
cleanup_metrics() {
  rm -f "$TMP_RECORDS"
}
trap cleanup_metrics EXIT INT TERM HUP

for _cc in $COMPILERS; do
  _sys="${LIBSCRIPT_ROOT_DIR}/build/zephyr-compare/${BOARD}-${_cc}"
  _t0=$(date +%s)
  FORCE_REBUILD=1 STACK='' "${SCRIPT_DIR}/build_firmware.sh" --board="$BOARD" --compiler="$_cc" --sysroot="$_sys"
  _t1=$(date +%s)
  _dur=$((_t1 - _t0))
  _elf="${_sys}/boot/zephyr.elf"
  _bin="${_sys}/boot/zephyr.bin"
  _elf_bytes=$(wc -c < "$_elf" | tr -d '[:space:]')
  _bin_bytes=$(wc -c < "$_bin" | tr -d '[:space:]')
  _syms=0
  if [ -f "${_sys}/boot/zephyr.map" ]; then
    _syms=$(wc -l < "${_sys}/boot/zephyr.map" | tr -d '[:space:]')
  fi
  printf '{"kernel":"zephyr","board":"%s","compiler":"%s","elf_bytes":%s,"bin_bytes":%s,"symbols":%s,"compile_seconds":%s}\n' \
    "$BOARD" "$_cc" "$_elf_bytes" "$_bin_bytes" "$_syms" "$_dur" >> "$TMP_RECORDS"
done

if command -v jq >/dev/null 2>&1; then
  jq -s '{schema_version:"1.0.0",kernel:"zephyr",results:.}' "$TMP_RECORDS" > "${OUT_JSON}.tmp"
  mv "${OUT_JSON}.tmp" "$OUT_JSON"
else
  cp -f "$TMP_RECORDS" "$OUT_JSON"
fi
printf '[OK] Wrote Zephyr multi-compiler differential report -> %s\n' "$OUT_JSON"
exit 0
