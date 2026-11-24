#!/bin/sh
# ## Overview
# End-to-end 2x-idempotency suite for `./libscript.sh package-as` across Linux, FreeBSD, illumos, ReactOS, Unikernels, and RTOS.
# ## Usage
# ./tests/test_package_as_kernels.sh
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

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
  printf 'Usage: %s\n' "$THIS_FILE"
  exit 0
fi

TEST_WORK="${TMPDIR:-/tmp}/libscript_pkg_kernels_$$"
mkdir -p "$TEST_WORK"
export LIBSCRIPT_BUILD_DIR="$TEST_WORK"

# ## cleanup_work
# Removes temporary test artifacts upon script exit.
cleanup_work() {
  rm -rf "$TEST_WORK"
}
trap cleanup_work EXIT INT TERM

# ## assert_cmd
# Executes a command with clean STACK and exits non-zero on failure.
assert_cmd() {
  _ac_desc="$1"
  shift
  printf '[TEST]     %s...\n' "$_ac_desc"
  STACK='' "$@"
}

# 1. Verify --help across all kernel/distro package-as targets
for _tgt in \
  linux-distro \
  linux-kernel \
  freebsd-distro \
  illumos-distro \
  reactos-distro \
  unikernel \
  unikernel-distro \
  rtos-distro \
  firmware-bin \
  direct-kernel \
  qcow2; do
  assert_cmd "Help check: package-as ${_tgt}" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as "$_tgt" --help >/dev/null
done

# 2. Export profiles via `config os` and verify uniform `package-as ... --profile ... --format ... --dry-run`
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=illumos/minimal-server --export="${TEST_WORK}/illumos-os.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=freebsd/freebsd-server-standard --export="${TEST_WORK}/freebsd-os.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=reactos/desktop-classic-i686 --export="${TEST_WORK}/reactos-os.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=linux/linux-minimal-headless-musl --export="${TEST_WORK}/linux-os.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=linux/linux-kernel-gcc-tiny --export="${TEST_WORK}/linux-kernel.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=unikernel/osv-cloud-runtime --export="${TEST_WORK}/unikernel-os.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=rtos/zephyr-cortex-m3-mcuboot-signed --export="${TEST_WORK}/zephyr-rtos.json" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --profile=rtos/freertos-riscv64-static-safety --export="${TEST_WORK}/freertos-rtos.json" >/dev/null

assert_cmd 'Dry-run illumos-distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as illumos-distro --profile "${TEST_WORK}/illumos-os.json" --format qcow2 --dry-run >/dev/null
assert_cmd 'Dry-run freebsd-distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as freebsd-distro --profile "${TEST_WORK}/freebsd-os.json" --format qcow2 --dry-run >/dev/null
assert_cmd 'Dry-run reactos-distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as reactos-distro --profile "${TEST_WORK}/reactos-os.json" --format qcow2 --dry-run >/dev/null
assert_cmd 'Dry-run linux-distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as linux-distro --profile "${TEST_WORK}/linux-os.json" --format qcow2 --dry-run >/dev/null
assert_cmd 'Dry-run linux-kernel' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as linux-kernel --profile "${TEST_WORK}/linux-kernel.json" --format direct-kernel --dry-run >/dev/null
assert_cmd 'Dry-run unikernel-distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as unikernel-distro --profile "${TEST_WORK}/unikernel-os.json" --format elf --dry-run >/dev/null
assert_cmd 'Dry-run rtos-distro (Zephyr)' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as rtos-distro --profile "${TEST_WORK}/zephyr-rtos.json" --format firmware-bin --dry-run >/dev/null
assert_cmd 'Dry-run rtos-distro (FreeRTOS)' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as rtos-distro --profile "${TEST_WORK}/freertos-rtos.json" --format firmware-elf --dry-run >/dev/null
assert_cmd 'Dry-run firmware-bin --profile' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as firmware-bin --profile "${TEST_WORK}/zephyr-rtos.json" --dry-run >/dev/null

# 3. Verify format-first `--profile` auto-dispatch (`qcow2` and `direct-kernel`) across OS families
assert_cmd 'Auto-dispatch qcow2 -> linux_distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as qcow2 --profile "${TEST_WORK}/linux-os.json" --dry-run >/dev/null
assert_cmd 'Auto-dispatch qcow2 -> freebsd_distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as qcow2 --profile "${TEST_WORK}/freebsd-os.json" --dry-run >/dev/null
assert_cmd 'Auto-dispatch qcow2 -> illumos_distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as qcow2 --profile "${TEST_WORK}/illumos-os.json" --dry-run >/dev/null
assert_cmd 'Auto-dispatch qcow2 -> reactos_distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as qcow2 --profile "${TEST_WORK}/reactos-os.json" --dry-run >/dev/null
assert_cmd 'Auto-dispatch direct-kernel -> linux_distro' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as direct-kernel --profile "${TEST_WORK}/linux-kernel.json" --dry-run >/dev/null

# 4. Verify 2x consecutive idempotency (`[SKIP]` on repeat execution) for Linux kernel & Unikernel packaging
cat <<'MIN_LINUX' > "${TEST_WORK}/linux-minimal-kernel-only.json"
{
  "schema_version": "1.0.0",
  "profile_name": "linux-minimal-kernel-only",
  "target": {
    "arch": "x86_64",
    "os_family": "linux-musl",
    "libc": "musl"
  },
  "kernel": {
    "provider": "linux-lts",
    "config_method": "tinyconfig"
  },
  "init_system": {
    "provider": "none"
  },
  "storage": {
    "disk_size_gib": 1,
    "partition_table": "none",
    "boot_mode": "direct-kernel",
    "bootloader": "none"
  },
  "components": []
}
MIN_LINUX

LINUX_DK_OUT="${TEST_WORK}/out-linux-dk"
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as linux-distro \
  --profile "${TEST_WORK}/linux-minimal-kernel-only.json" \
  --format direct-kernel \
  --output "$LINUX_DK_OUT" \
  --allow-stub >/dev/null

if [ ! -f "${LINUX_DK_OUT}/boot-manifest.json" ] || [ ! -f "${LINUX_DK_OUT}.stamp" ]; then
  printf '[FAIL] Expected Linux direct-kernel bundle and stamp at %s\n' "$LINUX_DK_OUT" >&2
  exit 1
fi

SECOND_LINUX_OUT=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as linux-distro \
  --profile "${TEST_WORK}/linux-minimal-kernel-only.json" \
  --format direct-kernel \
  --output "$LINUX_DK_OUT" \
  --allow-stub)
case "$SECOND_LINUX_OUT" in
  *'[SKIP]'*) ;;
  *)
    printf '[FAIL] Expected 2nd consecutive linux-distro run to emit [SKIP], got: %s\n' "$SECOND_LINUX_OUT" >&2
    exit 1
    ;;
esac

UNIKERNEL_OUT="${TEST_WORK}/out-osv.unikernel.elf"
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as unikernel-distro \
  --profile "${TEST_WORK}/unikernel-os.json" \
  --format elf \
  --output "$UNIKERNEL_OUT" \
  --allow-stub >/dev/null

SECOND_UK_OUT=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as unikernel-distro \
  --profile "${TEST_WORK}/unikernel-os.json" \
  --format elf \
  --output "$UNIKERNEL_OUT" \
  --allow-stub)
case "$SECOND_UK_OUT" in
  *'[SKIP]'*) ;;
  *)
    printf '[FAIL] Expected 2nd consecutive unikernel-distro run to emit [SKIP], got: %s\n' "$SECOND_UK_OUT" >&2
    exit 1
    ;;
esac

printf '[PASS] All unified kernel package-as syntax and 2x idempotency tests succeeded!\n'
