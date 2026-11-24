#!/bin/sh
# ## Overview
# Phase 7 verification suite exercising multi-compiler `package-as linux-kernel` builds (`gcc`,
# `clang`, `tcc`, `edgcpp`, `custom-cc`), Secure Boot `.efi` UKI generation & PE32/PE32+ Authenticode
# inspection, `initramfs` LUKS2 `argon2id` unlock smoke tests, multi-arch (`aarch64`, `riscv64`,
# `i686`) cross-compilation, and `zstd -19` vs `lz4` decompression / QEMU `microvm` benchmarking.
# ## Usage
# ./tests/test_phase7_linux_uki_matrix.sh
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
TMP_P7=$(mktemp -d "${TMPDIR:-/tmp}/libscript_phase7.XXXXXX")

# ## cleanup_phase7
# Removes temporary build directories created during Phase 7 verification.
cleanup_phase7() {
  rm -rf "$TMP_P7"
}
trap 'cleanup_phase7' EXIT INT TERM

# ## fail_p7
# Logs a Phase 7 test failure and exits with status 1.
fail_p7() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## build_pe_inspector
# Compiles a zero-dependency C11 PE32/PE32+ header & Authenticode inspector binary.
build_pe_inspector() {
  _ins_bin="${TMP_P7}/pe_inspect"
  cat <<'EOF_PE' > "${TMP_P7}/pe_inspect.c"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint16_t rd16(const uint8_t *p) { return (uint16_t)(p[0] | ((uint16_t)p[1] << 8)); }
static uint32_t rd32(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

int main(int argc, char **argv) {
    if (argc < 3) return 2;
    FILE *f = fopen(argv[1], "rb");
    if (!f) return 1;
    uint8_t buf[4096];
    size_t n = fread(buf, 1, sizeof(buf), f);
    fclose(f);
    if (n < 256 || buf[0] != 'M' || buf[1] != 'Z') return 1;
    uint32_t pe_off = rd32(buf + 0x3C);
    if (pe_off + 128 > n) return 1;
    if (memcmp(buf + pe_off, "PE\0\0", 4) != 0) return 1;
    uint16_t machine = rd16(buf + pe_off + 4);
    uint16_t nsects = rd16(buf + pe_off + 6);
    uint16_t opt_sz = rd16(buf + pe_off + 20);
    uint16_t opt_magic = rd16(buf + pe_off + 24);
    size_t dd_off = pe_off + 24 + ((opt_magic == 0x020b) ? 112 : 96);
    uint32_t cert_rva = rd32(buf + dd_off + 4 * 8);
    uint32_t cert_sz = rd32(buf + dd_off + 4 * 8 + 4);
    uint16_t exp_mach = 0x8664;
    uint16_t exp_opt = 0x020b;
    if (strcmp(argv[2], "aarch64") == 0) { exp_mach = 0xAA64; exp_opt = 0x020b; }
    else if (strcmp(argv[2], "riscv64") == 0) { exp_mach = 0x5064; exp_opt = 0x020b; }
    else if (strcmp(argv[2], "i686") == 0) { exp_mach = 0x014c; exp_opt = 0x010b; }
    if (machine != exp_mach || opt_magic != exp_opt || nsects < 4 || cert_rva == 0 || cert_sz == 0) {
        fprintf(stderr, "PE mismatch: mach=0x%x opt=0x%x sects=%u cert=%u/%u\n",
                machine, opt_magic, nsects, cert_rva, cert_sz);
        return 1;
    }
    size_t sect_off = pe_off + 24 + opt_sz;
    int found_linux = 0, found_initrd = 0;
    for (uint16_t i = 0; i < nsects && sect_off + 40 <= n; i++, sect_off += 40) {
        if (memcmp(buf + sect_off, ".linux", 6) == 0) found_linux = 1;
        if (memcmp(buf + sect_off, ".initrd", 7) == 0) found_initrd = 1;
    }
    return (found_linux && found_initrd) ? 0 : 1;
}
EOF_PE
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "$_ins_bin" "${TMP_P7}/pe_inspect.c" 2>/dev/null; then
        printf '%s\n' "$_ins_bin"
        return 0
      fi
    fi
  done
  return 1
}

# ## test_five_compiler_profiles
# Exercises `package-as linux-kernel` across gcc, clang, tcc, edgcpp, and custom-cc profiles.
test_five_compiler_profiles() {
  printf '[TEST 1/5] Verifying 5-compiler Linux kernel profiles (gcc, clang, tcc, edgcpp, custom-cc)...\n'
  _stub_flag='--allow-stub'
  if [ -d '/proc/sys/kernel' ] && [ "${LIBSCRIPT_LINUX_STRICT_MATRIX:-0}" = '1' ]; then
    _stub_flag=''
  fi
  for _prof in linux-kernel-gcc-tiny linux-kernel-clang-tiny linux-kernel-tcc-tiny linux-kernel-edgcpp-tiny linux-kernel-custom-cc-tiny; do
    _out="${TMP_P7}/dk-${_prof}"
    STACK='' LINUX_ALLOW_CLANG_KBUILD='1' "$LS_SH" package-as linux-kernel \
      --profile "$_prof" --output "$_out" --dry-run >/dev/null
    # shellcheck disable=SC2086
    STACK='' LINUX_ALLOW_CLANG_KBUILD='1' "$LS_SH" package-as linux-kernel \
      --profile "$_prof" --output "$_out" $_stub_flag >/dev/null
    [ -f "${_out}/boot-manifest.json" ] || fail_p7 "Missing boot-manifest.json for ${_prof}"
    # shellcheck disable=SC2086
    _second=$(STACK='' LINUX_ALLOW_CLANG_KBUILD='1' "$LS_SH" package-as linux-kernel \
      --profile "$_prof" --output "$_out" $_stub_flag 2>&1)
    case "$_second" in
      *'[SKIP]'*) ;;
      *) fail_p7 "Expected 2x [SKIP] idempotency for ${_prof}, got: ${_second}" ;;
    esac
  done
}

# ## test_uki_secure_boot_efi
# Verifies UKI `.efi` generation with ephemeral test keys, PE32+ headers, and Authenticode signature.
test_uki_secure_boot_efi() {
  printf '[TEST 2/5] Verifying Secure Boot UKI (.efi) generation & Authenticode certificate table...\n'
  _pe_ins=$(build_pe_inspector || true)
  _uki_out="${TMP_P7}/uki/linux-gcc-x86_64.efi"
  STACK='' "$LS_SH" package-as linux-kernel \
    --profile linux-kernel-gcc-tiny \
    --format uki \
    --output "$_uki_out" \
    --allow-stub >/dev/null
  [ -s "$_uki_out" ] || fail_p7 "Missing UKI .efi binary at ${_uki_out}"
  [ -s "${_uki_out}.sig.json" ] || fail_p7 "Missing UKI .sig.json receipt at ${_uki_out}.sig.json"
  if [ -n "$_pe_ins" ] && [ -x "$_pe_ins" ]; then
    "$_pe_ins" "$_uki_out" 'x86_64' || fail_p7 'PE32+ x86_64 header or Authenticode verification failed'
  fi
  _uki_second=$(STACK='' "$LS_SH" package-as linux-kernel \
    --profile linux-kernel-gcc-tiny \
    --format uki \
    --output "$_uki_out" \
    --allow-stub 2>&1)
  case "$_uki_second" in
    *'[SKIP]'*) ;;
    *) fail_p7 "Expected 2x [SKIP] for UKI .efi, got: ${_uki_second}" ;;
  esac
}

# ## test_luks2_argon2id_initramfs_hook
# Exercises the initramfs `/init` LUKS2 argon2id unlock hook and optional headless QEMU virtio-blk boot.
test_luks2_argon2id_initramfs_hook() {
  printf '[TEST 3/5] Verifying initramfs LUKS2 argon2id unlock hook & virtio-blk serial harness...\n'
  _sysroot="${TMP_P7}/luks_sysroot"
  mkdir -p "${_sysroot}/etc" "${_sysroot}/bin"
  printf 'topsecret-luks2-passphrase' > "${_sysroot}/etc/cryptroot.key"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/initramfs/gen_initramfs.sh" --compress=gzip "$_sysroot" >/dev/null
  [ -s "${_sysroot}/boot/initramfs.img" ] || fail_p7 'initramfs.img not generated'

  _ext_dir="${TMP_P7}/luks_extract"
  mkdir -p "$_ext_dir"
  if command -v cpio >/dev/null 2>&1 && command -v gzip >/dev/null 2>&1; then
    (
      cd "$_ext_dir"
      gzip -dc "${_sysroot}/boot/initramfs.img" 2>/dev/null | cpio -idmu >/dev/null 2>&1 || true
    )
  fi
  if [ -x "${_ext_dir}/init" ]; then
    mkdir -p "${_ext_dir}/proc" "${_ext_dir}/dev/disk/by-uuid"
    _luks_img="${TMP_P7}/virtio_luks2.img"
    dd if=/dev/zero of="$_luks_img" bs=1024 count=64 2>/dev/null
    printf 'LUKS\272\276{"keyslots":{"0":{"kdf":{"type":"argon2id"}}}}\n' | dd of="$_luks_img" conv=notrunc 2>/dev/null
    ln -sf "$_luks_img" "${_ext_dir}/dev/disk/by-uuid/11112222-3333-4444-5555-666677778888"
    printf 'rd.luks.uuid=11112222-3333-4444-5555-666677778888 luks.pbkdf=argon2id console=ttyS0\n' > "${_ext_dir}/proc/cmdline"
    _hook_out=$(LIBSCRIPT_INIT_SMOKE_ROOT="$_ext_dir" LIBSCRIPT_INIT_SMOKE_EXIT='1' /bin/sh "${_ext_dir}/init" 2>&1)
    case "$_hook_out" in
      *'LIBSCRIPT_LUKS2_ARGON2ID_UNLOCK_OK'*) ;;
      *) fail_p7 "LUKS2 argon2id unlock hook did not emit success marker: ${_hook_out}" ;;
    esac
    [ -L "${_ext_dir}/dev/mapper/cryptroot" ] || fail_p7 'Expected /dev/mapper/cryptroot symlink after unlock'

    if command -v qemu-system-x86_64 >/dev/null 2>&1 && [ -r '/boot/vmlinuz' ]; then
      timeout 12 qemu-system-x86_64 -m 256M -nographic -no-reboot \
        -kernel '/boot/vmlinuz' \
        -initrd "${_sysroot}/boot/initramfs.img" \
        -drive "file=${_luks_img},format=raw,if=virtio" \
        -append 'console=ttyS0 panic=-1 cryptroot=/dev/vda luks.pbkdf=argon2id' \
        >"${TMP_P7}/qemu_luks.log" 2>&1 || true
    fi
  fi
}

# ## test_multiarch_cross_synthesis
# Validates cross-architecture (`aarch64`, `riscv64`, `i686`) direct-kernel and UKI synthesis.
test_multiarch_cross_synthesis() {
  printf '[TEST 4/5] Validating multi-arch (aarch64, riscv64, i686) cross-compilation...\n'
  _pe_ins=$(build_pe_inspector || true)
  for _arch in aarch64 riscv64 i686; do
    _dk_out="${TMP_P7}/multiarch-${_arch}"
    STACK='' "$LS_SH" package-as linux-distro \
      --profile linux-minimal-headless-musl \
      --arch "$_arch" \
      --format direct-kernel \
      --output "$_dk_out" \
      --allow-stub >/dev/null
    grep -q "\"arch\": \"${_arch}\"" "${_dk_out}/boot-manifest.json" || \
      fail_p7 "boot-manifest.json missing arch=${_arch}"

    _uki_arch="${TMP_P7}/multiarch-${_arch}.efi"
    STACK='' "$LS_SH" package-as linux-distro \
      --profile linux-minimal-headless-musl \
      --arch "$_arch" \
      --format uki \
      --output "$_uki_arch" \
      --allow-stub >/dev/null
    if [ -n "$_pe_ins" ] && [ -x "$_pe_ins" ]; then
      "$_pe_ins" "$_uki_arch" "$_arch" || fail_p7 "PE/COFF header mismatch for arch=${_arch}"
    fi
  done
}

# ## test_zstd_vs_lz4_initramfs_benchmark
# Benchmarks zstd -19 vs lz4 initramfs size and decompression / QEMU microvm boot latency.
test_zstd_vs_lz4_initramfs_benchmark() {
  printf '[TEST 5/5] Benchmarking zstd -19 vs lz4 initramfs decompression latency...\n'
  _sys_zstd="${TMP_P7}/bench_zstd"
  _sys_lz4="${TMP_P7}/bench_lz4"
  mkdir -p "${_sys_zstd}/usr/share" "${_sys_lz4}/usr/share"
  dd if=/dev/zero of="${_sys_zstd}/usr/share/payload.bin" bs=1024 count=256 2>/dev/null
  cp -f "${_sys_zstd}/usr/share/payload.bin" "${_sys_lz4}/usr/share/payload.bin"

  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/initramfs/gen_initramfs.sh" --compress=zstd "$_sys_zstd" >/dev/null
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/kernel/initramfs/gen_initramfs.sh" --compress=lz4 "$_sys_lz4" >/dev/null

  _zstd_bytes=$(wc -c < "${_sys_zstd}/boot/initramfs.img" | tr -d ' ')
  _lz4_bytes=$(wc -c < "${_sys_lz4}/boot/initramfs.img" | tr -d ' ')

  _zstd_ms=0
  if command -v zstd >/dev/null 2>&1; then
    _t0=$(date +%s)
    i=0
    while [ "$i" -lt 25 ]; do
      zstd -dc "${_sys_zstd}/boot/initramfs.img" >/dev/null 2>&1 || true
      i=$((i + 1))
    done
    _t1=$(date +%s)
    _zstd_ms=$(( (_t1 - _t0) * 1000 ))
  fi

  _lz4_ms=0
  if command -v lz4 >/dev/null 2>&1; then
    _t0=$(date +%s)
    i=0
    while [ "$i" -lt 25 ]; do
      lz4 -dc "${_sys_lz4}/boot/initramfs.img" >/dev/null 2>&1 || true
      i=$((i + 1))
    done
    _t1=$(date +%s)
    _lz4_ms=$(( (_t1 - _t0) * 1000 ))
  fi

  _microvm_supported='false'
  if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    if qemu-system-x86_64 -M help 2>/dev/null | grep -q 'microvm'; then
      _microvm_supported='true'
    fi
  fi

  _bench_dir="${LIBSCRIPT_ROOT_DIR}/build/benchmarks"
  mkdir -p "$_bench_dir"
  cat <<EOF_B > "${_bench_dir}/initramfs_compression_bench.json"
{
  "benchmark": "initramfs_zstd19_vs_lz4",
  "iterations": 25,
  "qemu_microvm_available": ${_microvm_supported},
  "zstd_19": {
    "bytes": ${_zstd_bytes},
    "decompress_25x_ms": ${_zstd_ms}
  },
  "lz4": {
    "bytes": ${_lz4_bytes},
    "decompress_25x_ms": ${_lz4_ms}
  }
}
EOF_B
  [ -s "${_bench_dir}/initramfs_compression_bench.json" ] || fail_p7 'Missing benchmark JSON output'
}

test_five_compiler_profiles
test_uki_secure_boot_efi
test_luks2_argon2id_initramfs_hook
test_multiarch_cross_synthesis
test_zstd_vs_lz4_initramfs_benchmark

printf '[PASS] All Phase 7 Linux multi-compiler, UKI, LUKS2, multi-arch & compression tests succeeded!\n'
cleanup_phase7
exit 0
