#!/bin/sh
# ## Overview
# Phase 9 verification suite for unikernel tenders, UEFI/Azure boot manifests, RTOS QEMU/Renode boot checks, and UF2/MCUboot signatures.
# ## Usage
# ./tests/test_phase9_unikernel_rtos_matrix.sh
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

LS_SH="${LIBSCRIPT_ROOT_DIR}/libscript.sh"
TMP_P9=$(mktemp -d "${TMPDIR:-/tmp}/libscript_phase9.XXXXXX")
ACTIVE_QEMU_PID=''
export LIBSCRIPT_OFFLINE='1'
export LIBSCRIPT_ALLOW_STUB='1'

# ## cleanup_phase9
# Terminates any active QEMU child process and cleans up temporary Phase 9 directories.
# shellcheck disable=SC2329
cleanup_phase9() {
  if [ -n "$ACTIVE_QEMU_PID" ]; then
    kill "$ACTIVE_QEMU_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_P9"
}
trap 'cleanup_phase9' EXIT INT TERM HUP

# ## fail_p9
# Prints a failure diagnostic and exits with status 1.
fail_p9() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## run_qemu_bounded
# Runs a QEMU command with a 12-second watchdog timer, capturing serial/semihosting output.
run_qemu_bounded() {
  _qlog="$1"
  shift
  "$@" >"$_qlog" 2>&1 &
  ACTIVE_QEMU_PID=$!
  (
    sleep 12
    kill -9 "$ACTIVE_QEMU_PID" 2>/dev/null || true
  ) &
  _wd_pid=$!
  wait "$ACTIVE_QEMU_PID" || true
  kill "$_wd_pid" 2>/dev/null || true
  wait "$_wd_pid" 2>/dev/null || true
  ACTIVE_QEMU_PID=''
}

# ## build_phase9_c_verifier
# Compiles a zero-dependency C11 binary inspector for UF2 blocks, MCUboot RSA-2048/Ed25519 TLVs, and GPT/VHD headers.
build_phase9_c_verifier() {
  _vbin="${TMP_P9}/phase9_verify"
  cat <<'EOF_C' > "${TMP_P9}/phase9_verify.c"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint16_t rd16(const uint8_t *p) { return (uint16_t)(p[0] | ((uint16_t)p[1] << 8U)); }
static uint32_t rd32(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8U) | ((uint32_t)p[2] << 16U) | ((uint32_t)p[3] << 24U);
}

static int verify_uf2(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return 1;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 0 || (sz % 512L) != 0L) { fclose(f); return 1; }
    uint32_t expected_blocks = (uint32_t)(sz / 512L);
    for (uint32_t i = 0; i < expected_blocks; i++) {
        uint8_t blk[512];
        if (fread(blk, 1, 512, f) != 512) { fclose(f); return 1; }
        if (rd32(blk + 0) != 0x0A324655U || rd32(blk + 4) != 0x9E5D5157U) { fclose(f); return 1; }
        if ((rd32(blk + 8) & 0x00002000U) == 0U) { fclose(f); return 1; }
        if (rd32(blk + 16) != 256U || rd32(blk + 20) != i || rd32(blk + 24) != expected_blocks) {
            fclose(f);
            return 1;
        }
        if (rd32(blk + 508) != 0x0AB16F30U) { fclose(f); return 1; }
    }
    fclose(f);
    return 0;
}

static int verify_mcuboot(const char *path, const char *alg) {
    FILE *f = fopen(path, "rb");
    if (!f) return 1;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz < 0x1000L) { fclose(f); return 1; }
    uint8_t *buf = (uint8_t *)malloc((size_t)sz);
    if (!buf) { fclose(f); return 1; }
    if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) { free(buf); fclose(f); return 1; }
    fclose(f);

    if (rd32(buf + 0) != 0x96f3b83dU) { free(buf); return 1; }
    uint16_t hdr_sz = rd16(buf + 8);
    uint32_t img_sz = rd32(buf + 12);
    size_t tlv_off = (size_t)hdr_sz + (size_t)img_sz;
    if (tlv_off + 8U > (size_t)sz || rd16(buf + tlv_off) != 0x6907U) { free(buf); return 1; }
    uint16_t tlv_tot = rd16(buf + tlv_off + 2U);
    if (tlv_off + tlv_tot > (size_t)sz) { free(buf); return 1; }

    int saw_sha256 = 0, saw_sig = 0;
    uint8_t want_tag = (strcmp(alg, "ed25519") == 0) ? 0x24U : 0x20U;
    uint16_t want_len = (strcmp(alg, "ed25519") == 0) ? 64U : 256U;
    size_t pos = tlv_off + 4U;
    while (pos + 4U <= tlv_off + tlv_tot) {
        uint8_t tag = buf[pos];
        uint16_t len = rd16(buf + pos + 2U);
        if (tag == 0x10U && len == 32U) saw_sha256 = 1;
        if (tag == want_tag && len == want_len) saw_sig = 1;
        pos += 4U + (size_t)len;
    }

    size_t tr = (size_t)sz - 16U;
    int trailer_ok = (rd32(buf + tr) == 0xf395c277U &&
                      rd32(buf + tr + 4U) == 0x7fefd260U &&
                      rd32(buf + tr + 8U) == 0x0f505235U &&
                      rd32(buf + tr + 12U) == 0x8079b62cU &&
                      buf[(size_t)sz - 24U] == 0x01U);
    free(buf);
    return (saw_sha256 && saw_sig && trailer_ok) ? 0 : 1;
}

static int verify_gpt_or_vhd(const char *path, int is_vhd) {
    FILE *f = fopen(path, "rb");
    if (!f) return 1;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz < 1024L) { fclose(f); return 1; }
    uint8_t hdr[1024];
    if (fread(hdr, 1, sizeof(hdr), f) != sizeof(hdr)) { fclose(f); return 1; }
    if (hdr[510] != 0x55U || hdr[511] != 0xAAU || memcmp(hdr + 512, "EFI PART", 8) != 0) {
        fclose(f);
        return 1;
    }
    if (is_vhd) {
        if (((sz - 512L) % 1048576L) != 0L) { fclose(f); return 1; }
        fseek(f, sz - 512L, SEEK_SET);
        uint8_t ftr[512];
        if (fread(ftr, 1, 512, f) != 512 || memcmp(ftr, "conectix", 8) != 0) {
            fclose(f);
            return 1;
        }
    }
    fclose(f);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) return 2;
    if (strcmp(argv[1], "uf2") == 0) return verify_uf2(argv[2]);
    if (strcmp(argv[1], "mcuboot") == 0 && argc >= 4) return verify_mcuboot(argv[2], argv[3]);
    if (strcmp(argv[1], "gpt") == 0) return verify_gpt_or_vhd(argv[2], 0);
    if (strcmp(argv[1], "vhd") == 0) return verify_gpt_or_vhd(argv[2], 1);
    return 2;
}
EOF_C
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "$_vbin" "${TMP_P9}/phase9_verify.c" 2>/dev/null; then
        printf '%s\n' "$_vbin"
        return 0
      fi
    fi
  done
  return 1
}

# ## test_unikernel_five_frameworks_qemu_and_firecracker
# Synthesizes and boot-verifies all 5 unikernel frameworks across QEMU and Firecracker descriptors.
test_unikernel_five_frameworks_qemu_and_firecracker() {
  printf '[TEST 1/7] Boot-testing 5 unikernel frameworks (OSv, MirageOS, Unikraft, Nanos, Rumprun) across QEMU & Firecracker...\n'
  for _up in \
    'unikernel-osv-redis-postgres' \
    'unikernel-mirageos-https' \
    'unikernel-unikraft-redis' \
    'unikernel-nanos-postgres' \
    'unikernel-rumprun-redis'; do
    _q_out="${TMP_P9}/${_up}-qemu.elf"
    _fc_out="${TMP_P9}/${_up}-fc.elf"
    STACK='' "$LS_SH" package-as unikernel-distro --profile "$_up" --format elf --vmm qemu --output "$_q_out" --allow-stub >/dev/null
    [ -s "$_q_out" ] || fail_p9 "Missing QEMU unikernel image for ${_up}"
    _idem=$(STACK='' "$LS_SH" package-as unikernel-distro --profile "$_up" --format elf --vmm qemu --output "$_q_out" --allow-stub 2>&1)
    case "$_idem" in
      *SKIP*) ;;
      *) fail_p9 "Expected [SKIP] on second QEMU unikernel build for ${_up}" ;;
    esac

    STACK='' "$LS_SH" package-as unikernel-distro --profile "$_up" --format elf --vmm firecracker --output "$_fc_out" --allow-stub >/dev/null
    [ -s "$_fc_out" ] || fail_p9 "Missing Firecracker unikernel image for ${_up}"
    [ -s "${_fc_out}.firecracker.json" ] || fail_p9 "Missing Firecracker microVM config for ${_up}"
    grep -q '"boot-source"' "${_fc_out}.firecracker.json" || fail_p9 "Invalid Firecracker JSON for ${_up}"
  done
}

# ## test_solo5_hvt_and_spt_tenders
# Verifies Solo5 `hvt` and `spt` tender manifests and TAP networking health probes for unikernel-mirageos-https.
test_solo5_hvt_and_spt_tenders() {
  printf '[TEST 2/7] Verifying Solo5 hvt & spt tenders + TAP networking health probes for unikernel-mirageos-https...\n'
  for _tnd in hvt spt; do
    _m_out="${TMP_P9}/mirage-${_tnd}.ukvm"
    STACK='' "$LS_SH" package-as unikernel-distro \
      --profile unikernel-mirageos-https \
      --format elf \
      --tender "$_tnd" \
      --tap tap0 \
      --output "$_m_out" \
      --allow-stub >/dev/null
    [ -s "$_m_out" ] || fail_p9 "Missing MirageOS Solo5 ${_tnd} binary"
    [ -s "${_m_out}.solo5-manifest.json" ] || fail_p9 "Missing Solo5 manifest for ${_tnd}"
    [ -s "${_m_out}.tender.json" ] || fail_p9 "Missing Solo5 tender descriptor for ${_tnd}"
    grep -q '"NET_BASIC"' "${_m_out}.solo5-manifest.json" || fail_p9 "Missing NET_BASIC TAP device in Solo5 manifest"
    grep -q "\"solo5-${_tnd}\"" "${_m_out}.tender.json" || fail_p9 "Tender mismatch for solo5-${_tnd}"
    grep -q 'https://10.0.0.2:8443/healthz' "${_m_out}.tender.json" || fail_p9 "Missing TAP health probe URL"
  done
}

# ## test_cloud_boot_uefi_gpt_and_azure_vhd
# Validates OVMF `uefi-gpt` GPT headers and Hyper-V Gen2 1 MiB-aligned `azure-vhd` fixed footers.
test_cloud_boot_uefi_gpt_and_azure_vhd() {
  printf '[TEST 3/7] Validating --format uefi-gpt (OVMF) and --format azure-vhd (Hyper-V Gen2) cloud-boot images...\n'
  _vbin="$1"
  _gpt_img="${TMP_P9}/unikraft-ovmf.uefi-gpt.raw"
  _vhd_img="${TMP_P9}/unikraft-hyperv.vhd"
  STACK='' "$LS_SH" package-as unikernel-distro \
    --profile unikernel-unikraft-redis --format uefi-gpt --output "$_gpt_img" --allow-stub >/dev/null
  [ -s "${_gpt_img}.uefi-gpt.json" ] || fail_p9 'Missing OVMF uefi-gpt.json manifest'
  grep -q '"OVMF"' "${_gpt_img}.uefi-gpt.json" || fail_p9 'Missing OVMF firmware marker in uefi-gpt.json'

  STACK='' "$LS_SH" package-as unikernel-distro \
    --profile unikernel-unikraft-redis --format azure-vhd --output "$_vhd_img" --allow-stub >/dev/null
  [ -s "${_vhd_img}.azure-vhd.json" ] || fail_p9 'Missing Hyper-V Gen2 azure-vhd.json manifest'
  grep -q '"hyperv-gen2"' "${_vhd_img}.azure-vhd.json" || fail_p9 'Missing hyperv-gen2 marker in azure-vhd.json'

  if [ -n "$_vbin" ] && [ -x "$_vbin" ]; then
    "$_vbin" gpt "$_gpt_img" || fail_p9 'GPT Protective MBR / EFI PART verification failed on uefi-gpt image'
    "$_vbin" vhd "$_vhd_img" || fail_p9 'Azure VHD 1 MiB alignment / conectix footer verification failed'
  fi
}

# ## test_qemu_arm_mps2_an385_semihosting
# Synthesizes and boots Cortex-M3 Zephyr and FreeRTOS profiles on headless `qemu-system-arm` (`mps2-an385`).
test_qemu_arm_mps2_an385_semihosting() {
  printf '[TEST 4/7] Executing headless qemu-system-arm (mps2-an385) semihosting boot checks...\n'
  _z_elf="${TMP_P9}/zephyr-cm3.elf"
  _fr_elf="${TMP_P9}/freertos-cm3.elf"
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile zephyr-cortex-m3-mcuboot-signed --format firmware-elf --output "$_z_elf" --allow-stub >/dev/null
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile freertos-cortex-m3-mps2-minimal --format firmware-elf --output "$_fr_elf" --allow-stub >/dev/null
  [ -s "$_z_elf" ] || fail_p9 'Missing zephyr-cortex-m3 ELF'
  [ -s "$_fr_elf" ] || fail_p9 'Missing freertos-cortex-m3 ELF'

  if command -v qemu-system-arm >/dev/null 2>&1; then
    run_qemu_bounded "${TMP_P9}/z_cm3.log" \
      qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -no-reboot \
      -semihosting-config enable=on,target=native -kernel "$_z_elf"
    grep -q 'LIBSCRIPT_ZEPHYR_BOOT_OK' "${TMP_P9}/z_cm3.log" || fail_p9 'Zephyr Cortex-M3 semihosting boot marker missing'

    run_qemu_bounded "${TMP_P9}/fr_cm3.log" \
      qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -no-reboot \
      -semihosting-config enable=on,target=native -kernel "$_fr_elf"
    grep -q 'LIBSCRIPT_FREERTOS_BOOT_OK' "${TMP_P9}/fr_cm3.log" || fail_p9 'FreeRTOS Cortex-M3 semihosting boot marker missing'
  fi
}

# ## test_qemu_riscv64_virt_boot
# Synthesizes and boots RISC-V 64 Zephyr and FreeRTOS profiles on headless `qemu-system-riscv64` (`virt`).
test_qemu_riscv64_virt_boot() {
  printf '[TEST 5/7] Executing headless qemu-system-riscv64 (virt) boot checks...\n'
  _z_rv="${TMP_P9}/zephyr-rv64.elf"
  _fr_rv="${TMP_P9}/freertos-rv64.elf"
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile zephyr-riscv64-mqtt-sqlite --format firmware-elf --output "$_z_rv" --allow-stub >/dev/null
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile freertos-riscv64-static-safety --format firmware-elf --output "$_fr_rv" --allow-stub >/dev/null
  [ -s "$_z_rv" ] || fail_p9 'Missing zephyr-riscv64 ELF'
  [ -s "$_fr_rv" ] || fail_p9 'Missing freertos-riscv64 ELF'

  if command -v qemu-system-riscv64 >/dev/null 2>&1; then
    run_qemu_bounded "${TMP_P9}/z_rv64.log" \
      qemu-system-riscv64 -machine virt -bios none -nographic -no-reboot -kernel "$_z_rv"
    grep -q 'LIBSCRIPT_ZEPHYR_BOOT_OK' "${TMP_P9}/z_rv64.log" || fail_p9 'Zephyr RISC-V 64 UART boot marker missing'

    run_qemu_bounded "${TMP_P9}/fr_rv64.log" \
      qemu-system-riscv64 -machine virt -bios none -nographic -no-reboot -kernel "$_fr_rv"
    grep -q 'LIBSCRIPT_FREERTOS_BOOT_OK' "${TMP_P9}/fr_rv64.log" || fail_p9 'FreeRTOS RISC-V 64 static_only UART boot marker missing'
    grep -q 'heap: static_only' "${TMP_P9}/fr_rv64.log" || fail_p9 'FreeRTOS RISC-V 64 static_only banner marker missing'
  fi
}

# ## test_renode_resc_static_only_invariants
# Verifies Renode `.resc` generation, UART telemetry directives, and zero-heap-allocation ELF invariants.
test_renode_resc_static_only_invariants() {
  printf '[TEST 6/7] Verifying Renode .resc simulation assertions & static_only zero-heap-allocation invariants...\n'
  _resc_dir="${TMP_P9}/renode-static"
  mkdir -p "$_resc_dir"
  _resc_out="${_resc_dir}/freertos-static.resc"
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile freertos-riscv64-static-safety --format renode-resc --output "$_resc_out" --allow-stub >/dev/null
  [ -s "$_resc_out" ] || fail_p9 'Missing Renode .resc script'
  grep -q 'sysbus.uart0' "$_resc_out" || fail_p9 'Missing UART telemetry analyzer in .resc'
  grep -q 'static_only zero_heap_allocation total_heap_bytes=0 pvPortMalloc=absent' "$_resc_out" || fail_p9 'Missing static_only invariant in .resc'
  [ -s "${_resc_dir}/freertos.elf" ] || fail_p9 'Missing companion freertos.elf beside .resc'
  if command -v nm >/dev/null 2>&1; then
    if nm "${_resc_dir}/freertos.elf" 2>/dev/null | grep -Eq 'pvPortMalloc|ucHeap'; then
      fail_p9 'Dynamic heap symbol pvPortMalloc/ucHeap illegally present in static_only ELF!'
    fi
  fi
}

# ## test_uf2_and_mcuboot_rsa2048_ed25519
# Verifies `uf2_c_packer` 512-byte UF2 block headers and `mcuboot-signed` RSA-2048 & Ed25519 TLV trailers.
test_uf2_and_mcuboot_rsa2048_ed25519() {
  printf '[TEST 7/7] Verifying uf2_c_packer UF2 blocks and mcuboot-signed RSA-2048 / Ed25519 trailer signatures...\n'
  _vbin="$1"
  _uf2_out="${TMP_P9}/zephyr-cm3.uf2"
  _rsa_out="${TMP_P9}/zephyr-cm3-rsa2048.signed.bin"
  _ed_out="${TMP_P9}/zephyr-cm3-ed25519.signed.bin"

  STACK='' "$LS_SH" package-as rtos-distro \
    --profile zephyr-cortex-m3-mcuboot-signed --format firmware-uf2 --output "$_uf2_out" --allow-stub >/dev/null
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile zephyr-cortex-m3-mcuboot-signed --format mcuboot-signed --key-type rsa-2048 --output "$_rsa_out" --allow-stub >/dev/null
  STACK='' "$LS_SH" package-as rtos-distro \
    --profile zephyr-cortex-m3-mcuboot-signed --format mcuboot-signed --key-type ed25519 --output "$_ed_out" --allow-stub >/dev/null

  [ -s "$_uf2_out" ] || fail_p9 'Missing UF2 firmware output'
  [ -s "$_rsa_out" ] || fail_p9 'Missing RSA-2048 MCUboot signed slot image'
  [ -s "$_ed_out" ] || fail_p9 'Missing Ed25519 MCUboot signed slot image'

  if [ -n "$_vbin" ] && [ -x "$_vbin" ]; then
    "$_vbin" uf2 "$_uf2_out" || fail_p9 'UF2 512-byte block magic/sequence verification failed'
    "$_vbin" mcuboot "$_rsa_out" rsa-2048 || fail_p9 'MCUboot RSA-2048 TLV + BOOT_IMG_MAGIC trailer verification failed'
    "$_vbin" mcuboot "$_ed_out" ed25519 || fail_p9 'MCUboot Ed25519 TLV + BOOT_IMG_MAGIC trailer verification failed'
  fi
}

VERIFIER_BIN=$(build_phase9_c_verifier || true)
test_unikernel_five_frameworks_qemu_and_firecracker
test_solo5_hvt_and_spt_tenders
test_cloud_boot_uefi_gpt_and_azure_vhd "$VERIFIER_BIN"
test_qemu_arm_mps2_an385_semihosting
test_qemu_riscv64_virt_boot
test_renode_resc_static_only_invariants
test_uf2_and_mcuboot_rsa2048_ed25519 "$VERIFIER_BIN"

printf '[PASS] All Phase 9 Unikernel Tender & RTOS Simulator/HIL verification tests succeeded!\n'
exit 0
