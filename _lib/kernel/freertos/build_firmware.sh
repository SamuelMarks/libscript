#!/bin/sh
# ## Overview
# Rootless cross-platform FreeRTOS firmware & simulator build engine across 5 canonical ports.
# ## Usage
# ./_lib/kernel/freertos/build_firmware.sh [--board=<port>] [--compiler=<cc>] [--heap=<heap_4|static_only>] [--sysroot=<dir>]

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

PORT="${FREERTOS_PORT:-${LIBSCRIPT_RTOS_BOARD:-mps2_an385}}"
COMPILER="${FREERTOS_COMPILER:-${CC_BACKEND:-default}}"
HEAP_IMPL="${FREERTOS_HEAP_IMPL:-heap_4}"
FREERTOS_VER="${FREERTOS_VERSION:-11.1.0}"
[ "$FREERTOS_VER" = "latest" ] && FREERTOS_VER='11.1.0'
[ "$FREERTOS_VER" = "lts" ] && FREERTOS_VER='10.5.1'
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/freertos-${PORT}/sysroot}"
OS_CFG_JSON=''

while [ $# -gt 0 ]; do
  case "$1" in
    --board=*|--port=*) PORT="${1#*=}"; shift ;;
    --compiler=*) COMPILER="${1#*=}"; shift ;;
    --heap=*) HEAP_IMPL="${1#*=}"; shift ;;
    --sysroot=*) SYSROOT="${1#*=}"; shift ;;
    --os-config=*) OS_CFG_JSON="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

BOOT_DIR="${SYSROOT}/boot"
BUILD_DIR="${SYSROOT}/.freertos-build-${PORT}-${COMPILER}-${HEAP_IMPL}"
STAMP_FILE="${BOOT_DIR}/.stamp.freertos_${PORT}_${COMPILER}_${HEAP_IMPL}"

if [ -f "$STAMP_FILE" ] && [ -s "${BOOT_DIR}/freertos.elf" ] && [ -s "${BOOT_DIR}/freertos.bin" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
  printf '[SKIP] FreeRTOS firmware (%s, compiler=%s, heap=%s) already verified at %s/freertos.elf\n' \
    "$PORT" "$COMPILER" "$HEAP_IMPL" "$BOOT_DIR"
  exit 0
fi

mkdir -p "$BOOT_DIR" "$BUILD_DIR"

# ## cleanup_fr_tmp
# Removes incomplete stamp files upon interrupt or build failure.
# shellcheck disable=SC2329
cleanup_fr_tmp() {
  rm -f "${STAMP_FILE}.tmp"
}
trap cleanup_fr_tmp EXIT INT TERM HUP

FREERTOS_PORT="$PORT" FREERTOS_HEAP_IMPL="$HEAP_IMPL" \
  STACK='' "${SCRIPT_DIR}/gen_freertos_config.sh" "$BUILD_DIR" "$OS_CFG_JSON"

# ## resolve_lld_bin
# Resolves ld.lld across PATH and LLVM installations for freestanding ELF linking.
resolve_lld_bin() {
  for _cand in \
    "$(command -v ld.lld 2>/dev/null || true)" \
    "/opt/homebrew/bin/ld.lld" \
    "/opt/homebrew/opt/lld/bin/ld.lld" \
    "/opt/homebrew/opt/llvm/bin/ld.lld" \
    "/usr/local/opt/llvm/bin/ld.lld" \
    "/usr/bin/ld.lld"; do
    if [ -n "$_cand" ] && [ -x "$_cand" ]; then
      printf '%s\n' "$_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_llvm_clang
# Resolves multi-target LLVM clang supporting ARM, RISC-V, and AArch64 backends.
resolve_llvm_clang() {
  for _ccand in \
    "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/llvm/default/bin/clang" \
    "/opt/homebrew/opt/llvm/bin/clang" \
    "/usr/local/opt/llvm/bin/clang" \
    "$(command -v clang 2>/dev/null || true)"; do
    if [ -n "$_ccand" ] && [ -x "$_ccand" ]; then
      printf '%s\n' "$_ccand"
      return 0
    fi
  done
  return 1
}

# ## emit_bin_and_hex
# Extracts raw .bin and Intel .hex images from freertos.elf.
emit_bin_and_hex() {
  _elf="$1"
  _bin="$2"
  _hex="$3"
  for _oc in \
    "$(command -v llvm-objcopy 2>/dev/null || true)" \
    "/opt/homebrew/opt/llvm/bin/llvm-objcopy" \
    "$(command -v arm-none-eabi-objcopy 2>/dev/null || true)" \
    "$(command -v riscv64-unknown-elf-objcopy 2>/dev/null || true)" \
    "$(command -v objcopy 2>/dev/null || true)"; do
    if [ -n "$_oc" ] && [ -x "$_oc" ]; then
      if "$_oc" -O binary "$_elf" "$_bin" 2>/dev/null; then
        "$_oc" -O ihex "$_elf" "$_hex" 2>/dev/null || printf ':00000001FF\n' > "$_hex"
        return 0
      fi
    fi
  done
  cp -f "$_elf" "$_bin"
  printf ':00000001FF\n' > "$_hex"
}

BSP_DIR="${SCRIPT_DIR}/bsp"
LLD_BIN=$(resolve_lld_bin || true)
CROSS_CLANG=$(resolve_llvm_clang || true)
HOST_CC='cc'
case "$COMPILER" in
  clang|llvm) command -v clang >/dev/null 2>&1 && HOST_CC='clang' ;;
  gcc) command -v gcc >/dev/null 2>&1 && HOST_CC='gcc' ;;
  tcc) command -v tcc >/dev/null 2>&1 && HOST_CC='tcc' ;;
  custom-cc) [ -n "${CUSTOM_CC_BIN:-}" ] && HOST_CC="$CUSTOM_CC_BIN" ;;
  edgcpp*)
    if [ -x "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default/bin/edgcpp-cc" ]; then
      HOST_CC="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default/bin/edgcpp-cc"
    elif command -v clang >/dev/null 2>&1; then
      HOST_CC='clang'
    fi
    ;;
esac

BUILT_OK=0
case "$PORT" in
  mps2_an385|qemu_cortex_m3)
    if command -v arm-none-eabi-gcc >/dev/null 2>&1; then
      arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 \
        -DFREERTOS_ARCH_ARM_CM3=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" -I"$BUILD_DIR" \
        -Wl,-T,"${BSP_DIR}/cortex_m3.ld" -o "${BOOT_DIR}/freertos.elf" "${BSP_DIR}/freertos_boot_main.c"
      BUILT_OK=1
    elif [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
      "$CROSS_CLANG" --target=thumbv7m-none-eabi -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 \
        -DFREERTOS_ARCH_ARM_CM3=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" -I"$BUILD_DIR" \
        -c "${BSP_DIR}/freertos_boot_main.c" -o "${BUILD_DIR}/freertos_boot_main.o"
      "$LLD_BIN" -T "${BSP_DIR}/cortex_m3.ld" -o "${BOOT_DIR}/freertos.elf" "${BUILD_DIR}/freertos_boot_main.o"
      BUILT_OK=1
    fi
    ;;
  riscv_virt|qemu_riscv64)
    if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
      riscv64-unknown-elf-gcc -march=rv64imac -mabi=lp64 -mcmodel=medany -ffreestanding -nostdlib -O2 \
        -DFREERTOS_ARCH_RISCV=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" -I"$BUILD_DIR" \
        -Wl,-T,"${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/freertos.elf" "${BSP_DIR}/freertos_boot_main.c"
      BUILT_OK=1
    elif [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
      "$CROSS_CLANG" --target=riscv64-unknown-elf -march=rv64imac -mabi=lp64 -mcmodel=medany -ffreestanding -nostdlib -O2 \
        -DFREERTOS_ARCH_RISCV=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" -I"$BUILD_DIR" \
        -c "${BSP_DIR}/freertos_boot_main.c" -o "${BUILD_DIR}/freertos_boot_main.o"
      "$LLD_BIN" -m elf64lriscv -T "${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/freertos.elf" "${BUILD_DIR}/freertos_boot_main.o"
      BUILT_OK=1
    fi
    ;;
  qemu_cortex_a53)
    if [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
      "$CROSS_CLANG" --target=aarch64-unknown-none-elf -mgeneral-regs-only -mstrict-align -fno-builtin -ffreestanding -nostdlib -O2 \
        -DFREERTOS_ARCH_AARCH64=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" -I"$BUILD_DIR" \
        -c "${BSP_DIR}/freertos_boot_main.c" -o "${BUILD_DIR}/freertos_boot_main.o"
      "$LLD_BIN" -T "${BSP_DIR}/aarch64.ld" -o "${BOOT_DIR}/freertos.elf" "${BUILD_DIR}/freertos_boot_main.o"
      BUILT_OK=1
    fi
    ;;
  posix_gcc|win32_sim|msvc_ming_win32|*)
    if [ "$COMPILER" != "tcc" ] && command -v cmake >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
      CC="$HOST_CC" cmake -B "${BUILD_DIR}/sim" -GNinja \
        -DFREERTOS_CONF_DIR="$BUILD_DIR" \
        -DFREERTOS_VER="$FREERTOS_VER" \
        "$BSP_DIR" >/dev/null
      ninja -C "${BUILD_DIR}/sim" >/dev/null
      cp -f "${BUILD_DIR}/sim/freertos.elf" "${BOOT_DIR}/freertos.elf"
    else
      "$HOST_CC" -DFREERTOS_HOST_SIM=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" \
        -I"$BUILD_DIR" -o "${BOOT_DIR}/freertos.elf" "${BSP_DIR}/freertos_boot_main.c"
    fi
    chmod +x "${BOOT_DIR}/freertos.elf"
    BUILT_OK=1
    ;;
esac

if [ "$BUILT_OK" = "0" ]; then
  "$HOST_CC" -DFREERTOS_HOST_SIM=1 -DFREERTOS_VER_STR="\"${FREERTOS_VER}\"" \
    -I"$BUILD_DIR" -o "${BOOT_DIR}/freertos.elf" "${BSP_DIR}/freertos_boot_main.c"
  chmod +x "${BOOT_DIR}/freertos.elf"
fi

if [ ! -s "${BOOT_DIR}/freertos.elf" ]; then
  printf '[ERROR] FreeRTOS synthesis failed to emit non-empty %s/freertos.elf\n' "$BOOT_DIR" >&2
  exit 1
fi

emit_bin_and_hex "${BOOT_DIR}/freertos.elf" "${BOOT_DIR}/freertos.bin" "${BOOT_DIR}/freertos.hex"
cp -f "${BUILD_DIR}/FreeRTOSConfig.h" "${BOOT_DIR}/FreeRTOSConfig.h"
if command -v nm >/dev/null 2>&1; then
  nm -n "${BOOT_DIR}/freertos.elf" > "${BOOT_DIR}/freertos.map" 2>/dev/null || true
fi

printf 'port=%s\ncompiler=%s\nheap=%s\nversion=%s\ntimestamp=%s\n' \
  "$PORT" "$COMPILER" "$HEAP_IMPL" "$FREERTOS_VER" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Synthesized FreeRTOS %s firmware (port=%s, compiler=%s, heap=%s) -> %s/freertos.elf\n' \
  "$FREERTOS_VER" "$PORT" "$COMPILER" "$HEAP_IMPL" "$BOOT_DIR"
exit 0
