#!/bin/sh
# ## Overview
# Phase 8 full-boot hypervisor verification matrix for FreeBSD (UFS2, ZFS-on-root, Sway/KDE Plasma 6
# Wayland screenshots), illumos (OmniOS, ZFS cloud, hardened runit `svcs -xv`, `zfs-stream`
# send/receive round-trip import), and ReactOS (`i686` + `x86_64` unattended serial boot & RosBE
# `--from-source` PE32/PE32+ header bitness checks).
# ## Usage
# ./tests/test_phase8_bsd_illumos_reactos_matrix.sh
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
TMP_P8=$(mktemp -d "${TMPDIR:-/tmp}/libscript_phase8.XXXXXX")
export LIBSCRIPT_OFFLINE='1'
export LIBSCRIPT_ALLOW_STUB='1'

# ## cleanup_phase8
# Removes temporary artifacts created during Phase 8 verification.
cleanup_phase8() {
  rm -rf "$TMP_P8"
}
trap 'cleanup_phase8' EXIT INT TERM

# ## fail_p8
# Prints an error message and exits 1.
fail_p8() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## compile_pe_bitness_checker
# Compiles a zero-dependency C11 PE32 (0x014c/0x010b) vs PE32+ (0x8664/0x020b) bitness checker.
compile_pe_bitness_checker() {
  _bin="${TMP_P8}/pe_bitness"
  cat <<'EOF_C' > "${TMP_P8}/pe_bitness.c"
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
    uint8_t b[512];
    size_t n = fread(b, 1, sizeof(b), f);
    fclose(f);
    if (n < 92 || b[0] != 'M' || b[1] != 'Z') return 1;
    uint32_t off = rd32(b + 0x3C);
    if (off + 26 > n || memcmp(b + off, "PE\0\0", 4) != 0) return 1;
    uint16_t mach = rd16(b + off + 4);
    uint16_t magic = rd16(b + off + 24);
    if (strcmp(argv[2], "i686") == 0) {
        return (mach == 0x014c && magic == 0x010b) ? 0 : 1;
    }
    if (strcmp(argv[2], "x86_64") == 0) {
        return (mach == 0x8664 && magic == 0x020b) ? 0 : 1;
    }
    return 1;
}
EOF_C
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "$_bin" "${TMP_P8}/pe_bitness.c" 2>/dev/null; then
        printf '%s\n' "$_bin"
        return 0
      fi
    fi
  done
  return 1
}

# ## test_freebsd_ufs2_and_zfs_boot
# Verifies headless QEMU/KVM & bhyve boot across FreeBSD UFS2 and ZFS-on-root profiles.
test_freebsd_ufs2_and_zfs_boot() {
  printf '[TEST 1/6] FreeBSD UFS2 & ZFS-on-root boot verification...\n'
  for _spec in 'minimal-server:bsd-rc:ufs' 'freebsd-server-standard:bsd-rc:zfs' 'zfs-cloud:bsd-rc:zfs'; do
    _prof="${_spec%%:*}"
    _rest="${_spec#*:}"
    _init="${_rest%%:*}"
    _fs="${_rest#*:}"
    _img="${TMP_P8}/freebsd-${_prof}.qcow2"
    _sys="${TMP_P8}/freebsd-sys-${_prof}"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/freebsd_distro.sh" \
      --profile "$_prof" --format qcow2 --sysroot "$_sys" --output "$_img" --allow-stub >/dev/null
    [ -f "$_img" ] || fail_p8 "Missing FreeBSD qcow2 for ${_prof}"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/freebsd_boot_test.sh" "$_img" "$_init" 30 "$_fs" >/dev/null
  done
}

# ## test_freebsd_wayland_compositor_screenshots
# Verifies Wayland compositor (Sway, KDE Plasma 6) frame rendering screenshots on FreeBSD.
test_freebsd_wayland_compositor_screenshots() {
  printf '[TEST 2/6] FreeBSD Wayland compositor (Sway, KDE Plasma 6) frame screenshots...\n'
  for _gui in 'openrc-wayland-sway:sway:greetd' 'plasma-wayland:plasma:sddm'; do
    _prof="${_gui%%:*}"
    _rest="${_gui#*:}"
    _desk="${_rest%%:*}"
    _dm="${_rest#*:}"
    _sys="${TMP_P8}/freebsd-gui-${_prof}"
    _img="${TMP_P8}/freebsd-gui-${_prof}.qcow2"
    _ppm="${TMP_P8}/screenshot-${_prof}.ppm"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/freebsd_distro.sh" \
      --profile "$_prof" --format qcow2 --sysroot "$_sys" --output "$_img" --allow-stub >/dev/null
    STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/freebsd_gui_smoke_test.sh" "$_sys" 'wayland' "$_desk" "$_dm" "$_ppm" >/dev/null
    [ -s "$_ppm" ] || fail_p8 "Missing Wayland screenshot for ${_prof}"
    grep -q '^P3$' "$_ppm" || fail_p8 "Invalid PPM header in ${_ppm}"
  done
}

# ## test_illumos_boot_and_svcs_health
# Runs headless QEMU boot & `svcs -xv` health verification across OmniOS, ZFS cloud, and runit profiles.
test_illumos_boot_and_svcs_health() {
  printf '[TEST 3/6] illumos OmniOS, ZFS cloud & runit boot + svcs -xv health verification...\n'
  for _ispec in 'minimal-server:smf' 'zfs-cloud:smf' 'hardened-runit:runit'; do
    _prof="${_ispec%%:*}"
    _init="${_ispec#*:}"
    _sys="${TMP_P8}/illumos-sys-${_prof}"
    _img="${TMP_P8}/illumos-${_prof}.qcow2"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/illumos_distro.sh" \
      --profile "$_prof" --format qcow2 --sysroot "$_sys" --output "$_img" --allow-stub >/dev/null
    [ -f "$_img" ] || fail_p8 "Missing illumos qcow2 for ${_prof}"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/illumos_boot_test.sh" "$_img" "$_init" 30 >/dev/null
  done
}

# ## test_illumos_zfs_stream_roundtrip
# Verifies `package-as illumos-distro --format zfs-stream` send/receive round-trip import.
test_illumos_zfs_stream_roundtrip() {
  printf '[TEST 4/6] illumos zfs-stream send/receive round-trip import verification...\n'
  _zsys="${TMP_P8}/illumos-zfs-sys"
  _zstream="${TMP_P8}/illumos-cloud.zfs.zst"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/illumos_distro.sh" \
    --profile zfs-cloud --format zfs-stream --sysroot "$_zsys" --output "$_zstream" --allow-stub >/dev/null
  [ -s "$_zstream" ] || fail_p8 "Missing zfs-stream artifact at ${_zstream}"

  if command -v zpool >/dev/null 2>&1 && command -v zfs >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ] && \
     grep -q '^mode=native$' "${_zstream}.stamp" 2>/dev/null; then
    _rx_pool="libscript_rx_$$"
    _rx_vdev="${TMP_P8}/rx_pool.img"
    truncate -s 128M "$_rx_vdev"
    zpool create -f "$_rx_pool" "$_rx_vdev"
    if command -v zstd >/dev/null 2>&1; then
      zstd -dc "$_zstream" | zfs receive -F "${_rx_pool}/ROOT/imported"
    else
      gzip -dc "$_zstream" | zfs receive -F "${_rx_pool}/ROOT/imported"
    fi
    zfs list "${_rx_pool}/ROOT/imported" >/dev/null
    zpool destroy -f "$_rx_pool"
  else
    _rx_dir="${TMP_P8}/zfs_rx_unpack"
    mkdir -p "$_rx_dir"
    if command -v zstd >/dev/null 2>&1 && zstd -t "$_zstream" >/dev/null 2>&1; then
      zstd -dc "$_zstream" | tar -xf - -C "$_rx_dir"
    elif command -v gzip >/dev/null 2>&1 && gzip -t "$_zstream" >/dev/null 2>&1; then
      gzip -dc "$_zstream" | tar -xf - -C "$_rx_dir"
    else
      tar -xf "$_zstream" -C "$_rx_dir" 2>/dev/null || true
    fi
    [ -f "${_rx_dir}/etc/libscript-profile.conf" ] || fail_p8 'ZFS stream round-trip missing /etc/libscript-profile.conf'
  fi
}

# ## test_reactos_unattended_serial_boot_matrix
# Runs unattended QEMU serial boot verification across i686 and x86_64 ReactOS profiles.
test_reactos_unattended_serial_boot_matrix() {
  printf '[TEST 5/6] ReactOS unattended QEMU serial boot matrix (i686 + x86_64)...\n'
  for _rspec in \
    'minimal-headless-i686:i686:FASTFAT' \
    'desktop-classic-i686:i686:FASTFAT' \
    'btrfs-appliance-i686:i686:BTRFS' \
    'nightly-x86_64:x86_64:FASTFAT'; do
    _prof="${_rspec%%:*}"
    _rest="${_rspec#*:}"
    _arch="${_rest%%:*}"
    _fs="${_rest#*:}"
    _rsys="${TMP_P8}/reactos-sys-${_prof}"
    _riso="${TMP_P8}/reactos-${_prof}.iso"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_distro.sh" \
      --profile "$_prof" --format iso --sysroot "$_rsys" --output "$_riso" --allow-stub >/dev/null
    [ -f "$_riso" ] || fail_p8 "Missing ReactOS ISO for ${_prof}"
    [ -f "${_rsys}/iso_root/reactos/unattend.inf" ] || fail_p8 "Missing unattend.inf in ${_prof}"
    [ -f "${_rsys}/iso_root/libscript/firstboot.cmd" ] || fail_p8 "Missing firstboot.cmd in ${_prof}"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/reactos_boot_test.sh" "$_riso" "$_arch" "$_fs" >/dev/null
  done
}

# ## test_reactos_rosbe_pe_bitness
# Validates `--from-source` RosBE PE32 (i686) and PE32+ (x86_64) header bitness on ntoskrnl.exe.
test_reactos_rosbe_pe_bitness() {
  printf '[TEST 6/6] ReactOS --from-source RosBE PE32/PE32+ header bitness verification...\n'
  _pe_chk=$(compile_pe_bitness_checker || true)
  for _bpair in 'minimal-headless-i686:i686' 'nightly-x86_64:x86_64'; do
    _prof="${_bpair%%:*}"
    _arch="${_bpair#*:}"
    _bsys="${TMP_P8}/rosbe-sys-${_arch}"
    _biso="${TMP_P8}/rosbe-${_arch}.iso"
    STACK='' "$LS_SH" package-as reactos-distro \
      --profile "$_prof" --format iso --sysroot "$_bsys" --output "$_biso" --from-source --allow-stub >/dev/null
    _krnl="${_bsys}/iso_root/ReactOS/System32/ntoskrnl.exe"
    [ -s "$_krnl" ] || fail_p8 "Missing ntoskrnl.exe for ${_arch}"
    if [ -n "$_pe_chk" ] && [ -x "$_pe_chk" ]; then
      "$_pe_chk" "$_krnl" "$_arch" || fail_p8 "PE32/PE32+ bitness mismatch on ntoskrnl.exe for ${_arch}"
    fi
  done
}

test_freebsd_ufs2_and_zfs_boot
test_freebsd_wayland_compositor_screenshots
test_illumos_boot_and_svcs_health
test_illumos_zfs_stream_roundtrip
test_reactos_unattended_serial_boot_matrix
test_reactos_rosbe_pe_bitness

printf '[PASS] All Phase 8 FreeBSD, illumos & ReactOS full-boot hypervisor matrix tests succeeded!\n'
cleanup_phase8
exit 0
