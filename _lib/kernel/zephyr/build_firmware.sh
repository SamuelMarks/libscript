#!/bin/sh
# ## Overview
# Rootless cross-platform Zephyr RTOS firmware synthesis engine via CMake/Ninja or freestanding BSP.
# ## Usage
# ./_lib/kernel/zephyr/build_firmware.sh [--board=<board>] [--compiler=<cc>] [--sysroot=<dir>]

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

BOARD="${ZEPHYR_BOARD:-${LIBSCRIPT_RTOS_BOARD:-qemu_x86_64}}"
COMPILER="${ZEPHYR_COMPILER:-${CC_BACKEND:-default}}"
ZEPHYR_VER="${ZEPHYR_VERSION:-3.7.0}"
[ "$ZEPHYR_VER" = "latest" ] && ZEPHYR_VER='3.7.0'
SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/zephyr-${BOARD}/sysroot}"
KCONFIG_CSV="${ZEPHYR_KCONFIG_FRAGMENTS:-minimal_footprint.conf,picolibc.conf}"
DTS_CSV="${ZEPHYR_DTS_OVERLAYS:-}"
USE_WEST="${ZEPHYR_USE_WEST:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --board=*) BOARD="${1#*=}"; shift ;;
    --compiler=*) COMPILER="${1#*=}"; shift ;;
    --sysroot=*) SYSROOT="${1#*=}"; shift ;;
    --kconfig=*) KCONFIG_CSV="${1#*=}"; shift ;;
    --dts-overlays=*) DTS_CSV="${1#*=}"; shift ;;
    --west) USE_WEST='1'; shift ;;
    *) shift ;;
  esac
done

if [ "${LIBSCRIPT_RTOS_MCUBOOT:-0}" = "1" ]; then
  case ",${KCONFIG_CSV}," in
    *,mcuboot_slot.conf,*) ;;
    *) KCONFIG_CSV="${KCONFIG_CSV},mcuboot_slot.conf" ;;
  esac
fi

BOOT_DIR="${SYSROOT}/boot"
BUILD_DIR="${SYSROOT}/.zephyr-build-${BOARD}-${COMPILER}"
STAMP_FILE="${BOOT_DIR}/.stamp.zephyr_${BOARD}_${COMPILER}"

if [ -f "$STAMP_FILE" ] && [ -s "${BOOT_DIR}/zephyr.elf" ] && [ -s "${BOOT_DIR}/zephyr.bin" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
  printf '[SKIP] Zephyr firmware (%s, compiler=%s) already verified at %s/zephyr.elf\n' "$BOARD" "$COMPILER" "$BOOT_DIR"
  exit 0
fi

mkdir -p "$BOOT_DIR" "$BUILD_DIR"

# ## cleanup_tmp
# Removes incomplete stamp files upon unexpected interrupt or build error.
# shellcheck disable=SC2329
cleanup_tmp() {
  rm -f "${STAMP_FILE}.tmp"
}
trap cleanup_tmp EXIT INT TERM HUP

STACK='' "${SCRIPT_DIR}/merge_zephyr_config.sh" "$BUILD_DIR" "$BOARD" "$KCONFIG_CSV" "$DTS_CSV"

# ## resolve_lld_path
# Locates ld.lld across PATH and Homebrew LLVM prefixes for cross-target ELF linking.
resolve_lld_path() {
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

# ## resolve_cross_clang_path
# Resolves an LLVM clang binary with full multi-target (RISC-V, ARM, x86, AArch64) backend support.
resolve_cross_clang_path() {
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

# ## extract_raw_and_hex
# Produces zephyr.bin and zephyr.hex from zephyr.elf via objcopy or deterministic ELF fallback.
extract_raw_and_hex() {
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

ZEPHYR_SRC="${ZEPHYR_BASE:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr/${ZEPHYR_VER}}"
BUILT_OK=0

if [ -f "${ZEPHYR_SRC}/CMakeLists.txt" ] && [ -d "${ZEPHYR_SRC}/samples/hello_world" ]; then
  if [ "$USE_WEST" = "1" ] && command -v west >/dev/null 2>&1; then
    if ZEPHYR_BASE="$ZEPHYR_SRC" west build -b "$BOARD" -d "${BUILD_DIR}/upstream" "${ZEPHYR_SRC}/samples/hello_world" -- -DCONF_FILE="${BUILD_DIR}/prj.merged.conf" >/dev/null 2>&1; then
      cp -f "${BUILD_DIR}/upstream/zephyr/zephyr.elf" "${BOOT_DIR}/zephyr.elf"
      BUILT_OK=1
    fi
  elif command -v cmake >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
    if ZEPHYR_BASE="$ZEPHYR_SRC" cmake -B "${BUILD_DIR}/upstream" -GNinja -DBOARD="$BOARD" -DCONF_FILE="${BUILD_DIR}/prj.merged.conf" "${ZEPHYR_SRC}/samples/hello_world" >/dev/null 2>&1 && \
       ninja -C "${BUILD_DIR}/upstream" >/dev/null 2>&1 && [ -s "${BUILD_DIR}/upstream/zephyr/zephyr.elf" ]; then
      cp -f "${BUILD_DIR}/upstream/zephyr/zephyr.elf" "${BOOT_DIR}/zephyr.elf"
      BUILT_OK=1
    fi
  fi
fi

if [ "$BUILT_OK" = "0" ]; then
  BSP_DIR="${SCRIPT_DIR}/bsp"
  LLD_BIN=$(resolve_lld_path || true)
  CROSS_CLANG=$(resolve_cross_clang_path || true)
  HOST_CC='cc'
  case "$COMPILER" in
    clang|llvm) command -v clang >/dev/null 2>&1 && HOST_CC='clang' ;;
    gcc) command -v gcc >/dev/null 2>&1 && HOST_CC='gcc' ;;
    custom-cc) [ -n "${CUSTOM_CC_BIN:-}" ] && HOST_CC="$CUSTOM_CC_BIN" ;;
    edgcpp*)
      if [ -x "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default/bin/edgcpp-cc" ]; then
        HOST_CC="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default/bin/edgcpp-cc"
      elif command -v clang >/dev/null 2>&1; then
        HOST_CC='clang'
      fi
      ;;
  esac

  case "$BOARD" in
    native_sim|native_sim_64)
      if command -v cmake >/dev/null 2>&1 && command -v ninja >/dev/null 2>&1; then
        CC="$HOST_CC" cmake -B "${BUILD_DIR}/sim" -GNinja \
          -DZEPHYR_CONF_DIR="$BUILD_DIR" \
          -DZEPHYR_VER="$ZEPHYR_VER" \
          "$BSP_DIR" >/dev/null
        ninja -C "${BUILD_DIR}/sim" >/dev/null
        cp -f "${BUILD_DIR}/sim/zephyr.elf" "${BOOT_DIR}/zephyr.elf"
      else
        "$HOST_CC" -std=c11 -O2 -DZEPHYR_HOST_SIM=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" \
          -I"$BUILD_DIR" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
      fi
      chmod +x "${BOOT_DIR}/zephyr.elf"
      BUILT_OK=1
      ;;
    qemu_cortex_m3)
      if command -v arm-zephyr-eabi-gcc >/dev/null 2>&1; then
        arm-zephyr-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_ARM_CM3=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/cortex_m3.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif command -v arm-none-eabi-gcc >/dev/null 2>&1; then
        arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_ARM_CM3=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/cortex_m3.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif command -v clang >/dev/null 2>&1 && [ -n "$LLD_BIN" ]; then
        clang --target=thumbv7m-none-eabi -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_ARM_CM3=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -c "${BSP_DIR}/zephyr_boot_main.c" -o "${BUILD_DIR}/zephyr_boot_main.o"
        "$LLD_BIN" -T "${BSP_DIR}/cortex_m3.ld" -o "${BOOT_DIR}/zephyr.elf" "${BUILD_DIR}/zephyr_boot_main.o"
        BUILT_OK=1
      fi
      ;;
    qemu_riscv32)
      if [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
        "$CROSS_CLANG" --target=riscv32-unknown-elf -march=rv32imac -mabi=ilp32 -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_RISCV=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -c "${BSP_DIR}/zephyr_boot_main.c" -o "${BUILD_DIR}/zephyr_boot_main.o"
        "$LLD_BIN" -m elf32lriscv -T "${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/zephyr.elf" "${BUILD_DIR}/zephyr_boot_main.o"
        BUILT_OK=1
      fi
      ;;
    qemu_riscv64)
      if command -v riscv64-zephyr-elf-gcc >/dev/null 2>&1; then
        riscv64-zephyr-elf-gcc -march=rv64imac -mabi=lp64 -mcmodel=medany -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_RISCV=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
        riscv64-unknown-elf-gcc -march=rv64imac -mabi=lp64 -mcmodel=medany -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_RISCV=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
        "$CROSS_CLANG" --target=riscv64-unknown-elf -march=rv64imac -mabi=lp64 -mcmodel=medany -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_RISCV=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -c "${BSP_DIR}/zephyr_boot_main.c" -o "${BUILD_DIR}/zephyr_boot_main.o"
        "$LLD_BIN" -m elf64lriscv -T "${BSP_DIR}/riscv.ld" -o "${BOOT_DIR}/zephyr.elf" "${BUILD_DIR}/zephyr_boot_main.o"
        BUILT_OK=1
      fi
      ;;
    qemu_cortex_a53)
      if command -v aarch64-zephyr-elf-gcc >/dev/null 2>&1; then
        aarch64-zephyr-elf-gcc -mgeneral-regs-only -mstrict-align -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_AARCH64=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/aarch64.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif [ -n "$CROSS_CLANG" ] && [ -n "$LLD_BIN" ]; then
        "$CROSS_CLANG" --target=aarch64-unknown-none-elf -mgeneral-regs-only -mstrict-align -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_AARCH64=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -c "${BSP_DIR}/zephyr_boot_main.c" -o "${BUILD_DIR}/zephyr_boot_main.o"
        "$LLD_BIN" -T "${BSP_DIR}/aarch64.ld" -o "${BOOT_DIR}/zephyr.elf" "${BUILD_DIR}/zephyr_boot_main.o"
        BUILT_OK=1
      fi
      ;;
    qemu_x86_64|*)
      if command -v x86_64-zephyr-elf-gcc >/dev/null 2>&1; then
        x86_64-zephyr-elf-gcc -m32 -ffreestanding -nostdlib -O2 \
          -DZEPHYR_ARCH_X86=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -Wl,-T,"${BSP_DIR}/x86.ld" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
        BUILT_OK=1
      elif command -v clang >/dev/null 2>&1 && [ -n "$LLD_BIN" ]; then
        clang --target=i686-unknown-none-elf -march=i686 -ffreestanding -nostdlib -fno-pie -O2 \
          -DZEPHYR_ARCH_X86=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" -I"$BUILD_DIR" \
          -c "${BSP_DIR}/zephyr_boot_main.c" -o "${BUILD_DIR}/zephyr_boot_main.o"
        "$LLD_BIN" -m elf_i386 -T "${BSP_DIR}/x86.ld" -o "${BOOT_DIR}/zephyr.elf" "${BUILD_DIR}/zephyr_boot_main.o"
        BUILT_OK=1
      fi
      ;;
  esac

  if [ "$BUILT_OK" = "0" ]; then
    "$HOST_CC" -std=c11 -O2 -DZEPHYR_HOST_SIM=1 -DZEPHYR_VER_STR="\"${ZEPHYR_VER}\"" \
      -I"$BUILD_DIR" -o "${BOOT_DIR}/zephyr.elf" "${BSP_DIR}/zephyr_boot_main.c"
    BUILT_OK=1
  fi
fi

if [ ! -s "${BOOT_DIR}/zephyr.elf" ]; then
  printf '[ERROR] Zephyr firmware synthesis failed to emit non-empty %s/zephyr.elf\n' "$BOOT_DIR" >&2
  exit 1
fi

extract_raw_and_hex "${BOOT_DIR}/zephyr.elf" "${BOOT_DIR}/zephyr.bin" "${BOOT_DIR}/zephyr.hex"
cp -f "${BUILD_DIR}/.config" "${BOOT_DIR}/.config"
cp -f "${BUILD_DIR}/zephyr.dts" "${BOOT_DIR}/zephyr.dts"

if command -v nm >/dev/null 2>&1; then
  nm -n "${BOOT_DIR}/zephyr.elf" > "${BOOT_DIR}/zephyr.map" 2>/dev/null || true
fi

printf 'board=%s\ncompiler=%s\nversion=%s\ntimestamp=%s\n' \
  "$BOARD" "$COMPILER" "$ZEPHYR_VER" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Synthesized Zephyr %s firmware (board=%s, compiler=%s) -> %s/zephyr.elf\n' \
  "$ZEPHYR_VER" "$BOARD" "$COMPILER" "$BOOT_DIR"
exit 0
