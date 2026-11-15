#!/bin/sh
# ## Overview
# Headless Zephyr RTOS boot verification suite across QEMU (qemu_x86_64, qemu_cortex_m3,
# qemu_riscv64, qemu_cortex_a53) and native_sim, asserting boot banner and payload readiness.
#
# ## Usage
# ./tests/zephyr_boot_test.sh

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

TMP_ZBOOT=$(mktemp -d "${TMPDIR:-/tmp}/libscript_zboot.XXXXXX")
ACTIVE_PID=''

# ## cleanup_zboot
# Terminates any background QEMU child process and removes temporary build directories.
# shellcheck disable=SC2329
cleanup_zboot() {
  if [ -n "$ACTIVE_PID" ]; then
    kill "$ACTIVE_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_ZBOOT"
}
trap cleanup_zboot EXIT INT TERM HUP

# ## run_with_timeout
# Runs a command with a bounded watchdog timer and writes stdout/stderr to the target log file.
run_with_timeout() {
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

# ## assert_zephyr_banner
# Asserts that a captured serial log contains both the Zephyr OS banner and LIBSCRIPT_ZEPHYR_BOOT_OK.
assert_zephyr_banner() {
  _board="$1"
  _log="$2"
  grep -q '\*\*\* Booting Zephyr OS build' "$_log" || {
    printf '[FAIL] Missing Zephyr boot banner for board %s\n' "$_board" >&2
    cat "$_log" >&2
    exit 1
  }
  grep -q 'LIBSCRIPT_ZEPHYR_BOOT_OK' "$_log" || {
    printf '[FAIL] Missing LIBSCRIPT_ZEPHYR_BOOT_OK marker for board %s\n' "$_board" >&2
    cat "$_log" >&2
    exit 1
  }
  printf '[PASS] Zephyr %s booted cleanly and emitted LIBSCRIPT_ZEPHYR_BOOT_OK.\n' "$_board"
}

STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=native_sim --sysroot="${TMP_ZBOOT}/native_sim"
run_with_timeout "${TMP_ZBOOT}/native_sim.log" "${TMP_ZBOOT}/native_sim/boot/zephyr.elf"
assert_zephyr_banner "native_sim" "${TMP_ZBOOT}/native_sim.log"

if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=qemu_x86_64 --sysroot="${TMP_ZBOOT}/qemu_x86_64"
  run_with_timeout "${TMP_ZBOOT}/qemu_x86_64.log" qemu-system-x86_64 -nographic -no-reboot -kernel "${TMP_ZBOOT}/qemu_x86_64/boot/zephyr.elf"
  assert_zephyr_banner "qemu_x86_64" "${TMP_ZBOOT}/qemu_x86_64.log"
fi

if command -v qemu-system-arm >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=qemu_cortex_m3 --sysroot="${TMP_ZBOOT}/qemu_cortex_m3"
  run_with_timeout "${TMP_ZBOOT}/qemu_cortex_m3.log" qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "${TMP_ZBOOT}/qemu_cortex_m3/boot/zephyr.elf"
  assert_zephyr_banner "qemu_cortex_m3" "${TMP_ZBOOT}/qemu_cortex_m3.log"
fi

if command -v qemu-system-riscv64 >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=qemu_riscv64 --sysroot="${TMP_ZBOOT}/qemu_riscv64"
  if file "${TMP_ZBOOT}/qemu_riscv64/boot/zephyr.elf" 2>/dev/null | grep -qi 'RISC-V'; then
    run_with_timeout "${TMP_ZBOOT}/qemu_riscv64.log" qemu-system-riscv64 -machine virt -bios none -nographic -kernel "${TMP_ZBOOT}/qemu_riscv64/boot/zephyr.elf"
    assert_zephyr_banner "qemu_riscv64" "${TMP_ZBOOT}/qemu_riscv64.log"
  fi
fi

printf '[PASS] All Zephyr RTOS QEMU & native_sim boot assertions succeeded!\n'
exit 0
