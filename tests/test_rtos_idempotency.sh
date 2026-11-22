#!/bin/sh
# ## Overview
# 2x consecutive idempotency, UF2/MCUboot artifact determinism, and stamp-invalidation recovery
# test suite for Zephyr RTOS and FreeRTOS pipelines.
#
# ## Usage
# ./tests/test_rtos_idempotency.sh

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

TMP_IDEM=$(mktemp -d "${TMPDIR:-/tmp}/libscript_rtos_idem.XXXXXX")

# ## cleanup_idem
# Removes isolated LIBSCRIPT_HOME and temporary build directories on exit.
# shellcheck disable=SC2329
cleanup_idem() {
  rm -rf "$TMP_IDEM"
}
trap cleanup_idem EXIT INT TERM HUP

# ## fail_idem
# Emits a failure message and exits with status 1.
fail_idem() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

export LIBSCRIPT_HOME="${TMP_IDEM}/home"
export SOURCE_DATE_EPOCH='1700000000'
mkdir -p "$LIBSCRIPT_HOME"

printf '=== [1/3] Verifying 2x Consecutive Version Manager Install Idempotency ===\n'
for _k in zephyr freertos; do
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_k" lts >/dev/null
  OUT2=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_k" lts)
  printf '%s\n' "$OUT2" | grep -q 'already installed' || fail_idem "2nd install of ${_k} did not report already installed"
done

printf '=== [2/3] Verifying 2x Firmware Build & Packaging Idempotency (UF2 + MCUboot) ===\n'
Z_SYS="${TMP_IDEM}/zsys"
STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=qemu_cortex_m3 --sysroot="$Z_SYS" >/dev/null
Z_PASS2=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/zephyr/build_firmware.sh" --board=qemu_cortex_m3 --sysroot="$Z_SYS")
printf '%s\n' "$Z_PASS2" | grep -q '\[SKIP\]' || fail_idem 'Zephyr build_firmware pass 2 did not [SKIP]'

UF2_OUT="${TMP_IDEM}/out/zephyr.uf2"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/firmware_bin.sh" --format=firmware-uf2 --kernel=zephyr --board=qemu_cortex_m3 "$Z_SYS" "$UF2_OUT" >/dev/null
CK1=$(cksum "$UF2_OUT")
UF2_PASS2=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/firmware_bin.sh" --format=firmware-uf2 --kernel=zephyr --board=qemu_cortex_m3 "$Z_SYS" "$UF2_OUT")
CK2=$(cksum "$UF2_OUT")
printf '%s\n' "$UF2_PASS2" | grep -q '\[SKIP\]' || fail_idem 'firmware-uf2 pass 2 did not [SKIP]'
[ "$CK1" = "$CK2" ] || fail_idem 'UF2 checksum mutated across idempotent pass 2'

MCU_OUT="${TMP_IDEM}/out/freertos.signed.bin"
FR_SYS="${TMP_IDEM}/frsys"
STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=mps2_an385 --sysroot="$FR_SYS" >/dev/null
FR_PASS2=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=mps2_an385 --sysroot="$FR_SYS")
printf '%s\n' "$FR_PASS2" | grep -q '\[SKIP\]' || fail_idem 'FreeRTOS build_firmware pass 2 did not [SKIP]'
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/firmware_bin.sh" --format=mcuboot-signed --kernel=freertos --board=mps2_an385 "$FR_SYS" "$MCU_OUT" >/dev/null
[ -s "$MCU_OUT" ] || fail_idem 'MCUboot signed output is empty'

printf '=== [3/3] Verifying Stamp Invalidation Recovery on Deleted ELF ===\n'
rm -f "${FR_SYS}/boot/freertos.elf"
FR_REBUILD=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/freertos/build_firmware.sh" --board=mps2_an385 --sysroot="$FR_SYS")
printf '%s\n' "$FR_REBUILD" | grep -q '\[OK\] Synthesized FreeRTOS' || fail_idem 'Deleting freertos.elf did not invalidate stamp and trigger rebuild'
[ -s "${FR_SYS}/boot/freertos.elf" ] || fail_idem 'Rebuilt freertos.elf missing after recovery'

printf '[PASS] RTOS 2x Consecutive Idempotency & Stamp Recovery Suite PASSED!\n'
exit 0
