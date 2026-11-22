#!/bin/sh
# ## Overview
# Tier 2 RTOS firmware exporter supporting ELF, BIN, HEX, UF2, MCUboot-signed, and Renode bundles.
# ## Usage
# ./synthesis/formats/firmware_bin.sh [--format=<fmt>] [--kernel=<zephyr|freertos>] [--board=<board>] <sysroot> <out_path>

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

FORMAT='firmware-elf'
KERNEL_KIND="${LIBSCRIPT_TARGET_OS:-zephyr}"
BOARD="${LIBSCRIPT_RTOS_BOARD:-qemu_x86_64}"
SYSROOT=''
OUT_PATH=''

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--format=<firmware-elf|firmware-bin|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc>] [--kernel=<zephyr|freertos>] [--board=<board>] <sysroot> <out_path>\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --kernel=*) KERNEL_KIND="${1#*=}"; shift ;;
    --board=*) BOARD="${1#*=}"; shift ;;
    *)
      if [ -z "$SYSROOT" ]; then
        SYSROOT="$1"
      else
        OUT_PATH="$1"
      fi
      shift
      ;;
  esac
done

[ -n "$SYSROOT" ] || SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
[ -n "$OUT_PATH" ] || OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${KERNEL_KIND}-${BOARD}.${FORMAT}"

STAMP_FILE="${OUT_PATH}.stamp"
if [ -f "$STAMP_FILE" ] && [ -s "$OUT_PATH" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
  printf '[SKIP] Firmware artifact already packaged: %s\n' "$OUT_PATH"
  exit 0
fi

mkdir -p "$(dirname "$OUT_PATH")" "${SYSROOT}/boot"

if [ ! -s "${SYSROOT}/boot/zephyr.elf" ] && [ ! -s "${SYSROOT}/boot/freertos.elf" ]; then
  LIBSCRIPT_TARGET_OS="$KERNEL_KIND" LIBSCRIPT_RTOS_BOARD="$BOARD" \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/kernel_stage.sh" install "$SYSROOT"
fi

ELF_SRC="${SYSROOT}/boot/zephyr.elf"
BIN_SRC="${SYSROOT}/boot/zephyr.bin"
HEX_SRC="${SYSROOT}/boot/zephyr.hex"
if [ "$KERNEL_KIND" = "freertos" ] || [ "$KERNEL_KIND" = "rtos-freertos" ] || [ ! -s "$ELF_SRC" ]; then
  if [ -s "${SYSROOT}/boot/freertos.elf" ]; then
    ELF_SRC="${SYSROOT}/boot/freertos.elf"
    BIN_SRC="${SYSROOT}/boot/freertos.bin"
    HEX_SRC="${SYSROOT}/boot/freertos.hex"
  fi
fi

# ## ensure_uf2_packer
# Compiles the zero-dependency C11 UF2 block encoder once into LIBSCRIPT_HOME.
ensure_uf2_packer() {
  _cache="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/firmware-tools/bin"
  mkdir -p "$_cache"
  _bin="${_cache}/uf2_c_packer"
  if [ -x "$_bin" ]; then
    printf '%s\n' "$_bin"
    return 0
  fi
  for _cc in cc gcc clang; do
    if command -v "$_cc" >/dev/null 2>&1; then
      if "$_cc" -std=c11 -O2 -o "${_bin}.tmp" "${SCRIPT_DIR}/uf2_c_packer.c"; then
        mv "${_bin}.tmp" "$_bin"
        printf '%s\n' "$_bin"
        return 0
      fi
    fi
  done
  return 1
}

# ## emit_launch_wrappers
# Emits idempotent run_firmware.sh and run_firmware.cmd wrappers alongside packaged firmware.
emit_launch_wrappers() {
  _out_dir=$(dirname "$OUT_PATH")
  _elf_abs="$1"
  cat <<RUNSH > "${_out_dir}/run_firmware.sh"
#!/bin/sh
set -feu
BOARD="\${1:-${BOARD}}"
ELF="\${2:-${_elf_abs}}"
case "\$BOARD" in
  qemu_cortex_m3|mps2_an385)
    exec qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "\$ELF"
    ;;
  qemu_riscv64|riscv_virt)
    exec qemu-system-riscv64 -machine virt -bios none -nographic -kernel "\$ELF"
    ;;
  qemu_cortex_a53)
    exec qemu-system-aarch64 -machine virt -cpu cortex-a53 -nographic -kernel "\$ELF"
    ;;
  native_sim*|posix_gcc)
    exec "\$ELF"
    ;;
  *)
    exec qemu-system-x86_64 -nographic -no-reboot -kernel "\$ELF"
    ;;
esac
RUNSH
  chmod +x "${_out_dir}/run_firmware.sh"

  cat <<RUNCMD > "${_out_dir}/run_firmware.cmd"
@echo off
set "BOARD=%~1"
if "%BOARD%"=="" set "BOARD=${BOARD}"
set "ELF=%~2"
if "%ELF%"=="" set "ELF=${_elf_abs}"
if /I "%BOARD%"=="mps2_an385" (
    qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "%ELF%"
    exit /b %ERRORLEVEL%
)
if /I "%BOARD%"=="qemu_cortex_m3" (
    qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "%ELF%"
    exit /b %ERRORLEVEL%
)
if /I "%BOARD%"=="win32_sim" (
    "%ELF%"
    exit /b %ERRORLEVEL%
)
qemu-system-x86_64 -nographic -no-reboot -kernel "%ELF%"
RUNCMD
}

case "$FORMAT" in
  firmware-elf)
    cp -f "$ELF_SRC" "${OUT_PATH}.tmp"
    mv "${OUT_PATH}.tmp" "$OUT_PATH"
    ;;
  firmware-bin)
    cp -f "$BIN_SRC" "${OUT_PATH}.tmp"
    mv "${OUT_PATH}.tmp" "$OUT_PATH"
    ;;
  firmware-hex)
    cp -f "$HEX_SRC" "${OUT_PATH}.tmp"
    mv "${OUT_PATH}.tmp" "$OUT_PATH"
    ;;
  firmware-uf2)
    _packer=$(ensure_uf2_packer)
    "$_packer" "$BIN_SRC" "${OUT_PATH}.tmp"
    mv "${OUT_PATH}.tmp" "$OUT_PATH"
    ;;
  mcuboot-signed)
    STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/bootloaders/mcuboot/sign_firmware.sh" "$BIN_SRC" "$OUT_PATH"
    ;;
  renode-resc)
    cp -f "$ELF_SRC" "$(dirname "$OUT_PATH")/$(basename "$ELF_SRC")"
    cat <<RESC > "${OUT_PATH}.tmp"
# LibScript Renode headless simulation script (${KERNEL_KIND} / ${BOARD})
using sysbus
mach create "${KERNEL_KIND}-${BOARD}"
showAnalyzer sysbus.uart0
macro reset
"""
    sysbus LoadELF @$(dirname "$OUT_PATH")/$(basename "$ELF_SRC")
"""
runMacro \$reset
RESC
    mv "${OUT_PATH}.tmp" "$OUT_PATH"
    ;;
  *)
    printf '[ERROR] Unsupported firmware format: %s\n' "$FORMAT" >&2
    exit 1
    ;;
esac

emit_launch_wrappers "$ELF_SRC"
printf 'format=%s\nkernel=%s\nboard=%s\ntimestamp=%s\n' \
  "$FORMAT" "$KERNEL_KIND" "$BOARD" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Packaged %s (%s, board=%s) -> %s\n' "$KERNEL_KIND" "$FORMAT" "$BOARD" "$OUT_PATH"
exit 0
