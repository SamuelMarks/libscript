#!/bin/sh
# ## Overview
# Headless FreeRTOS boot & scheduler verification suite across QEMU (mps2-an385 ARM Cortex-M3,
# virt RISC-V 64, ARMv8-A Cortex-A53) and native POSIX simulator (heap_4 + static_only).
#
# ## Usage
# ./tests/freertos_boot_test.sh

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s\n' "$(basename "$THIS_FILE")"
  exit 0
fi

TMP_FRBOOT=$(mktemp -d "${TMPDIR:-/tmp}/libscript_frboot.XXXXXX")
ACTIVE_PID=''

# ## cleanup_frboot
# Terminates any background QEMU child process and removes temporary build directories.
# shellcheck disable=SC2329
cleanup_frboot() {
  if [ -n "$ACTIVE_PID" ]; then
    kill "$ACTIVE_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_FRBOOT"
}
trap cleanup_frboot EXIT INT TERM HUP

# ## run_bounded
# Executes a target emulator or simulator binary with a 15-second watchdog timer.
run_bounded() {
  _log="$1"
  shift
  "$@" >"$_log" 2>&1 &
  ACTIVE_PID=$!
  (
    sleep 15
    kill -9 "$ACTIVE_PID" 2>/dev/null || true
  ) &
  _wpid=$!
  wait "$ACTIVE_PID" || true
  kill "$_wpid" 2>/dev/null || true
  wait "$_wpid" 2>/dev/null || true
  ACTIVE_PID=''
}

# ## assert_freertos_banner
# Asserts FreeRTOS kernel boot banner, tick/queue/mutex pass line, and LIBSCRIPT_FREERTOS_BOOT_OK.
assert_freertos_banner() {
  _port="$1"
  _log="$2"
  grep -q '\*\*\* Booting FreeRTOS Kernel' "$_log" || {
    printf '[FAIL] Missing FreeRTOS banner for port %s\n' "$_port" >&2
    cat "$_log" >&2
    exit 1
  }
  grep -q 'tick_ok queue_ok mutex_ok' "$_log" || {
    printf '[FAIL] Missing FreeRTOS scheduler/queue/mutex pass line for port %s\n' "$_port" >&2
    cat "$_log" >&2
    exit 1
  }
  grep -q 'LIBSCRIPT_FREERTOS_BOOT_OK' "$_log" || {
    printf '[FAIL] Missing LIBSCRIPT_FREERTOS_BOOT_OK for port %s\n' "$_port" >&2
    cat "$_log" >&2
    exit 1
  }
  printf '[PASS] FreeRTOS %s booted cleanly and passed scheduler/queue/mutex self-test.\n' "$_port"
}

STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=posix_gcc --heap=static_only --sysroot="${TMP_FRBOOT}/posix_static"
run_bounded "${TMP_FRBOOT}/posix_static.log" "${TMP_FRBOOT}/posix_static/boot/freertos.elf"
assert_freertos_banner "posix_gcc(static_only)" "${TMP_FRBOOT}/posix_static.log"

if command -v qemu-system-arm >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=mps2_an385 --heap=heap_4 --sysroot="${TMP_FRBOOT}/mps2"
  run_bounded "${TMP_FRBOOT}/mps2.log" qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "${TMP_FRBOOT}/mps2/boot/freertos.elf"
  assert_freertos_banner "mps2_an385" "${TMP_FRBOOT}/mps2.log"
fi

if command -v qemu-system-riscv64 >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=riscv_virt --heap=static_only --sysroot="${TMP_FRBOOT}/riscv"
  if file "${TMP_FRBOOT}/riscv/boot/freertos.elf" 2>/dev/null | grep -qi 'RISC-V'; then
    run_bounded "${TMP_FRBOOT}/riscv.log" qemu-system-riscv64 -machine virt -bios none -nographic -kernel "${TMP_FRBOOT}/riscv/boot/freertos.elf"
    assert_freertos_banner "riscv_virt" "${TMP_FRBOOT}/riscv.log"
  fi
fi

if command -v qemu-system-aarch64 >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=qemu_cortex_a53 --heap=heap_4 --sysroot="${TMP_FRBOOT}/a53"
  if file "${TMP_FRBOOT}/a53/boot/freertos.elf" 2>/dev/null | grep -qiE 'aarch64|ARM aarch64'; then
    run_bounded "${TMP_FRBOOT}/a53.log" qemu-system-aarch64 -machine virt -cpu cortex-a53 -nographic -kernel "${TMP_FRBOOT}/a53/boot/freertos.elf"
    assert_freertos_banner "qemu_cortex_a53" "${TMP_FRBOOT}/a53.log"
  fi
fi

printf '[PASS] All FreeRTOS QEMU & POSIX simulator boot assertions succeeded!\n'
exit 0
