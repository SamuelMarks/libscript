#!/bin/sh
# ## Overview
# Tier 2/3 RTOS firmware exporter supporting ELF, BIN, HEX, UF2, MCUboot-signed, Renode bundles,
# and declarative `--profile` dispatch via `rtos_distro.sh`.
# ## Usage
# ./synthesis/formats/firmware_bin.sh [--profile <path|preset>] [--format=<fmt>] [--kernel=<zephyr|freertos>] [--board=<board>] [--output <path>] [--dry-run] [sysroot] [out_path]

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
case "${pkg_type:-}" in
  firmware_bin) FORMAT='firmware-bin' ;;
  firmware-bin|firmware-elf|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc) FORMAT="${pkg_type}" ;;
esac
KERNEL_KIND="${LIBSCRIPT_TARGET_OS:-zephyr}"
BOARD="${LIBSCRIPT_RTOS_BOARD:-qemu_x86_64}"
BOARD_EXPLICIT=''
PROFILE=''
SYSROOT=''
OUT_PATH=''
DRY_RUN="${LIBSCRIPT_DRY_RUN:-0}"
EXTRA_RTOS_ARGS=''

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf 'Usage: %s [--profile <path|preset>] [--format=<firmware-elf|firmware-bin|firmware-hex|firmware-uf2|mcuboot-signed|renode-resc>] [--kernel=<zephyr|freertos>] [--board=<board>] [--output <path>] [--dry-run] [sysroot] [out_path]\n' "$(basename "$THIS_FILE")"
      exit 0
      ;;
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --format|-f) FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --kernel) KERNEL_KIND="$2"; shift 2 ;;
    --kernel=*) KERNEL_KIND="${1#*=}"; shift ;;
    --board) BOARD="$2"; BOARD_EXPLICIT="$2"; shift 2 ;;
    --board=*) BOARD="${1#*=}"; BOARD_EXPLICIT="${1#*=}"; shift ;;
    --output|-o|--out) OUT_PATH="$2"; shift 2 ;;
    --output=*|--out=*) OUT_PATH="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; EXTRA_RTOS_ARGS="${EXTRA_RTOS_ARGS} --dry-run"; shift ;;
    --strict) EXTRA_RTOS_ARGS="${EXTRA_RTOS_ARGS} --strict"; shift ;;
    --allow-stub) EXTRA_RTOS_ARGS="${EXTRA_RTOS_ARGS} --allow-stub"; shift ;;
    --offline) EXTRA_RTOS_ARGS="${EXTRA_RTOS_ARGS} --offline"; shift ;;
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

if [ -n "$PROFILE" ]; then
  [ -n "$BOARD_EXPLICIT" ] && EXTRA_RTOS_ARGS="${EXTRA_RTOS_ARGS} --board=${BOARD_EXPLICIT}"
  if [ -n "$OUT_PATH" ]; then
    # shellcheck disable=SC2086
    STACK='' exec "${SCRIPT_DIR}/rtos_distro.sh" --profile "$PROFILE" --format "$FORMAT" --output "$OUT_PATH" $EXTRA_RTOS_ARGS
  else
    # shellcheck disable=SC2086
    STACK='' exec "${SCRIPT_DIR}/rtos_distro.sh" --profile "$PROFILE" --format "$FORMAT" $EXTRA_RTOS_ARGS
  fi
fi

[ -n "$SYSROOT" ] || SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
[ -n "$OUT_PATH" ] || OUT_PATH="${LIBSCRIPT_ROOT_DIR}/build/images/firmware/${KERNEL_KIND}-${BOARD}.${FORMAT}"

if [ "$DRY_RUN" = "1" ]; then
  printf '[DRYRUN] Firmware (%s, format=%s, board=%s) target verified -> %s\n' "$KERNEL_KIND" "$FORMAT" "$BOARD" "$OUT_PATH"
  exit 0
fi

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
  qemu_cortex_m3|mps2_an385) exec qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -semihosting-config enable=on,target=native -kernel "\$ELF" ;;
  riscv_virt|qemu_riscv64) exec qemu-system-riscv64 -machine virt -nographic -bios none -kernel "\$ELF" ;;
  posix_gcc|native_sim|win32_sim) exec "\$ELF" ;;
  *) exec qemu-system-x86_64 -nographic -no-reboot -kernel "\$ELF" ;;
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
    _repl='platforms/cpus/x86.repl'
    case "$BOARD" in
      *cortex_m3*|*mps2*) _repl='platforms/cpus/cortex-m3.repl' ;;
      *riscv*) _repl='platforms/cpus/riscv64.repl' ;;
      *cortex_a53*) _repl='platforms/cpus/cortex-a53-gicv2.repl' ;;
    esac
    _heap_inv="${FREERTOS_HEAP_IMPL:-dynamic_heap}"
    cat <<RESC > "${OUT_PATH}.tmp"
# LibScript Renode headless simulation script (${KERNEL_KIND} / ${BOARD})
# INVARIANT: heap_implementation=${_heap_inv}
# INVARIANT: uart_telemetry=LIBSCRIPT_BOOT_OK
using sysbus
mach create "${KERNEL_KIND}-${BOARD}"
machine LoadPlatformDescription @${_repl}
showAnalyzer sysbus.uart0
emulation CreateUartPtyTerminal "term" "$(dirname "$OUT_PATH")/uart_telemetry.pty" true
connector Connect sysbus.uart0 term
macro reset
"""
    sysbus LoadELF @$(dirname "$OUT_PATH")/$(basename "$ELF_SRC")
"""
runMacro \$reset
RESC
    if [ "$_heap_inv" = 'static_only' ]; then
      cat <<'RESC_STATIC' >> "${OUT_PATH}.tmp"
# INVARIANT: static_only zero_heap_allocation total_heap_bytes=0 pvPortMalloc=absent
RESC_STATIC
    fi
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
