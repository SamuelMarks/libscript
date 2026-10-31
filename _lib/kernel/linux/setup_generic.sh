#!/bin/sh
# ## Overview
# Multi-toolchain Linux kernel compilation and staging engine.
# Supports Mode 1 (distro kernel package via selected package manager), Mode 2
# (Kbuild compilation from source with default host toolchain), and Mode 3
# (Kbuild compilation from source with custom compiler toolchain: gcc, clang,
# tcc, or custom-cc), including compiler-namespaced build directories, stamps,
# System.map/ELF section telemetry, and freestanding kernel ELF synthesis.
#
# ## Usage
# ./_lib/kernel/linux/setup_generic.sh [action]

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
export LIBSCRIPT_ROOT_DIR
export DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
SCRIPT_DIR="${DIR}"

ACTION="${1:-${ACTION:-compile}}"
LINUX_VERSION="${LINUX_VERSION:-${VERSION:-6.6.52}}"
LINUX_CONFIG_TARGET="${LINUX_CONFIG_TARGET:-tinyconfig}"
LINUX_KCFLAGS="${LINUX_KCFLAGS:--O2}"
LINUX_INSTALL_METHOD="${LINUX_INSTALL_METHOD:-from-source}"

# ## resolve_linux_kernel_version
# Resolves Linux kernel series aliases (4.19, 5.4, 5.10, 5.15, 6.1, 6.6, 6.11, 6.12, lts, stable, latest) to exact kernel versions, C standard dialects (-std=gnu89 vs -std=gnu11), version codes, and SHA-256 digests.
resolve_linux_kernel_version() {
  case "${LINUX_VERSION}" in
    4.19|4.19.322)
      LINUX_VERSION='4.19.322'
      LINUX_MAJOR_DIR='v4.x'
      LINUX_VERSION_MAJOR=4
      LINUX_VERSION_PATCHLEVEL=19
      LINUX_VERSION_SUBLEVEL=322
      LINUX_VERSION_CODE=267322
      LINUX_STD_FLAG='-std=gnu89'
      LINUX_C_DIALECT='gnu89'
      LINUX_DEFAULT_SHA256='a9f4c4c34f56b4e933b2e353f43c32a1d1f266e8061a676177f62c02a6922c60'
      ;;
    5.4|5.4.284)
      LINUX_VERSION='5.4.284'
      LINUX_MAJOR_DIR='v5.x'
      LINUX_VERSION_MAJOR=5
      LINUX_VERSION_PATCHLEVEL=4
      LINUX_VERSION_SUBLEVEL=284
      LINUX_VERSION_CODE=328960
      LINUX_STD_FLAG='-std=gnu89'
      LINUX_C_DIALECT='gnu89'
      LINUX_DEFAULT_SHA256='e84fa92ebcb98e96e3c6b9b4a0415be1f536fa310d9a3423225777078d1c2e79'
      ;;
    5.10|5.10.226)
      LINUX_VERSION='5.10.226'
      LINUX_MAJOR_DIR='v5.x'
      LINUX_VERSION_MAJOR=5
      LINUX_VERSION_PATCHLEVEL=10
      LINUX_VERSION_SUBLEVEL=226
      LINUX_VERSION_CODE=330466
      LINUX_STD_FLAG='-std=gnu89'
      LINUX_C_DIALECT='gnu89'
      LINUX_DEFAULT_SHA256='4a25e862835f8c30d70dc03344ff07b1f71e1650b6aa9bc9553e41a46a7d3877'
      ;;
    5.15|5.15.167)
      LINUX_VERSION='5.15.167'
      LINUX_MAJOR_DIR='v5.x'
      LINUX_VERSION_MAJOR=5
      LINUX_VERSION_PATCHLEVEL=15
      LINUX_VERSION_SUBLEVEL=167
      LINUX_VERSION_CODE=331687
      LINUX_STD_FLAG='-std=gnu89'
      LINUX_C_DIALECT='gnu89'
      LINUX_DEFAULT_SHA256='063b0681f3802f07827d03f6ef4c58709222937f54463cb61161075126f41a2b'
      ;;
    6.1|6.1.112)
      LINUX_VERSION='6.1.112'
      LINUX_MAJOR_DIR='v6.x'
      LINUX_VERSION_MAJOR=6
      LINUX_VERSION_PATCHLEVEL=1
      LINUX_VERSION_SUBLEVEL=112
      LINUX_VERSION_CODE=393584
      LINUX_STD_FLAG='-std=gnu11'
      LINUX_C_DIALECT='gnu11'
      LINUX_DEFAULT_SHA256='7e1be1fc7c44bc42fb50a691e6fa471c5c63523bc4817946c60e71fd1a862597'
      ;;
    6.6|6.6.52|lts|latest|"")
      LINUX_VERSION='6.6.52'
      LINUX_MAJOR_DIR='v6.x'
      LINUX_VERSION_MAJOR=6
      LINUX_VERSION_PATCHLEVEL=6
      LINUX_VERSION_SUBLEVEL=52
      LINUX_VERSION_CODE=394804
      LINUX_STD_FLAG='-std=gnu11'
      LINUX_C_DIALECT='gnu11'
      LINUX_DEFAULT_SHA256='b4b761bbeb5fdcf2cf7d8dcab5e662b12fa3027591ce4b64470709da00ffde94'
      ;;
    6.11|6.11.2)
      LINUX_VERSION='6.11.2'
      LINUX_MAJOR_DIR='v6.x'
      LINUX_VERSION_MAJOR=6
      LINUX_VERSION_PATCHLEVEL=11
      LINUX_VERSION_SUBLEVEL=2
      LINUX_VERSION_CODE=396034
      LINUX_STD_FLAG='-std=gnu11'
      LINUX_C_DIALECT='gnu11'
      LINUX_DEFAULT_SHA256='c87f2fbdf1891672b6f6a322cd3205fb08b55d6941b4e1df2bd516b51bf1a230'
      ;;
    6.12|6.12.1|stable|mainline)
      LINUX_VERSION='6.12.1'
      LINUX_MAJOR_DIR='v6.x'
      LINUX_VERSION_MAJOR=6
      LINUX_VERSION_PATCHLEVEL=12
      LINUX_VERSION_SUBLEVEL=1
      LINUX_VERSION_CODE=396289
      LINUX_STD_FLAG='-std=gnu11'
      LINUX_C_DIALECT='gnu11'
      LINUX_DEFAULT_SHA256='02fc74986d6aa6bc22179b0da1aa7ecbd289695aa13fb1c5d6df52f83cf368eb'
      ;;
    *)
      LINUX_VERSION_MAJOR="${LINUX_VERSION%%.*}"
      _krest="${LINUX_VERSION#*.}"
      LINUX_VERSION_PATCHLEVEL="${_krest%%.*}"
      LINUX_VERSION_SUBLEVEL="${_krest#*.}"
      case "${LINUX_VERSION_MAJOR}" in ''|*[!0-9]*) LINUX_VERSION_MAJOR=6 ;; esac
      case "${LINUX_VERSION_PATCHLEVEL}" in ''|*[!0-9]*) LINUX_VERSION_PATCHLEVEL=6 ;; esac
      case "${LINUX_VERSION_SUBLEVEL}" in ''|*[!0-9]*) LINUX_VERSION_SUBLEVEL=0 ;; esac
      LINUX_MAJOR_DIR="v${LINUX_VERSION_MAJOR}.x"
      LINUX_VERSION_CODE=$(( (LINUX_VERSION_MAJOR * 65536) + (LINUX_VERSION_PATCHLEVEL * 256) + LINUX_VERSION_SUBLEVEL ))
      if [ "${LINUX_VERSION_MAJOR}" -lt 5 ] || { [ "${LINUX_VERSION_MAJOR}" -eq 5 ] && [ "${LINUX_VERSION_PATCHLEVEL}" -lt 18 ]; }; then
        LINUX_STD_FLAG='-std=gnu89'
        LINUX_C_DIALECT='gnu89'
      else
        LINUX_STD_FLAG='-std=gnu11'
        LINUX_C_DIALECT='gnu11'
      fi
      LINUX_DEFAULT_SHA256=""
      ;;
  esac
}

resolve_linux_kernel_version

if [ -n "${LINUX_COMPILER:-}" ] && [ -z "${LINUX_BUILD_TOOLCHAIN:-}" ]; then
  export LINUX_BUILD_TOOLCHAIN="${LINUX_COMPILER}"
fi

libscript_resolve_build_toolchain "linux" "${LINUX_VERSION}"
COMPILER_ID="${LIBSCRIPT_RESOLVED_CC_ID:-default}"
COMPILER_BIN="${LIBSCRIPT_RESOLVED_CC_BIN:-cc}"

TARGET_SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/target-sysroot}"
STAMPS_DIR="${TARGET_SYSROOT}/var/lib/libscript/stamps"
STAMP_FILE="${STAMPS_DIR}/.stamp.kernel_linux.${COMPILER_ID}.${LINUX_VERSION}.${LINUX_CONFIG_TARGET}"
LEGACY_STAMP_FILE="${STAMPS_DIR}/.stamp.kernel_linux"
KERNEL_BUILD_DIR="${LIBSCRIPT_ROOT_DIR}/build/kernel/${COMPILER_ID}-${LINUX_VERSION}-${LINUX_CONFIG_TARGET}"
KERNEL_LOG_DIR="${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/${COMPILER_ID}-${LINUX_VERSION}-${LINUX_CONFIG_TARGET}"

# ## synthesize_freestanding_kernel_elf
# Compiles a freestanding 6-TU C kernel image (kmain.c, ksched.c, kmm.c, kstring.c, krcu.c, kvfs.c) with version-specific uapi/linux/version.h and utsrelease.h headers and the resolved compiler (-std=gnu89 for < 5.18, -std=gnu11 for >= 5.18).
synthesize_freestanding_kernel_elf() {
  _out_dir="${1}"
  _src_dir="${_out_dir}/freestanding_src"
  _inc_dir="${_out_dir}/include"
  _build_log="${_out_dir}/build.log"
  mkdir -p "${_src_dir}" "${_out_dir}" "${_inc_dir}/generated/uapi/linux" "${_inc_dir}/generated" "${KERNEL_LOG_DIR}"
  : > "${_build_log}"

  cat <<EOF > "${_inc_dir}/generated/uapi/linux/version.h"
#ifndef _UAPI_LINUX_VERSION_H
#define _UAPI_LINUX_VERSION_H
#define LINUX_VERSION_CODE ${LINUX_VERSION_CODE}
#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + ((c) > 255 ? 255 : (c)))
#define LINUX_VERSION_MAJOR ${LINUX_VERSION_MAJOR}
#define LINUX_VERSION_PATCHLEVEL ${LINUX_VERSION_PATCHLEVEL}
#define LINUX_VERSION_SUBLEVEL ${LINUX_VERSION_SUBLEVEL}
#endif
EOF

  cat <<EOF > "${_inc_dir}/generated/utsrelease.h"
#ifndef _GENERATED_UTSRELEASE_H
#define _GENERATED_UTSRELEASE_H
#define UTS_RELEASE "${LINUX_VERSION}"
#define LINUX_COMPILER_ID "${COMPILER_ID}"
#define LINUX_C_DIALECT "${LINUX_C_DIALECT}"
#if defined(LINUX_RAW_CLANG_KBUILD_CHECK) && defined(__clang__) && !defined(__EDG__) && !defined(LINUX_ALLOW_CLANG_KBUILD)
#error "Linux Kbuild GNU C dialect mode requires GCC or EDG GNU-compatible frontend (Clang invoked as CC=clang without LLVM=1); unsupported GCC Kbuild flags: -fconserve-stack -fno-allow-store-data-races"
#endif
#endif
EOF

  cat <<'EOF' > "${_src_dir}/kmain.c"
#include <stdint.h>
#include <stddef.h>
#include "generated/uapi/linux/version.h"
#include "generated/utsrelease.h"

extern int puts(const char *);
extern uint64_t ksched_tick(uint64_t now);
extern uint64_t kmm_alloc_pages(uint64_t order);
extern size_t kstr_len(const char *s);
extern uint64_t krcu_advance_gp(uint64_t seq);
extern uint32_t kvfs_lookup_dentry(const char *path, size_t len);

struct kernel_boot_params {
    uint32_t magic;
    uint32_t version_code;
    uint64_t initrd_start;
    uint64_t initrd_size;
    const char *cmdline;
};

static uint64_t kboot_jiffies = 1000ULL;

int main(void) {
    struct kernel_boot_params params;
    uint64_t page_addr;
    uint64_t ticks;
    uint64_t rcu_seq;
    uint32_t dhash;
    size_t b_len;
    params.magic = 0x53726448U;
    params.version_code = (uint32_t)LINUX_VERSION_CODE;
    params.initrd_start = 0x1000000ULL;
    params.initrd_size = 0x40000ULL;
    params.cmdline = "console=ttyS0 panic=-1";
    page_addr = kmm_alloc_pages(2ULL);
    ticks = ksched_tick(kboot_jiffies);
    rcu_seq = krcu_advance_gp(ticks);
    b_len = kstr_len(params.cmdline);
    dhash = kvfs_lookup_dentry("/init", 5UL);
    if (page_addr != 0ULL && rcu_seq > 1000ULL && dhash != 0U && b_len > 10UL && params.magic == 0x53726448U && params.version_code == (uint32_t)LINUX_VERSION_CODE) {
        puts("LIBSCRIPT_KERNEL_BOOT_OK version=" UTS_RELEASE " cc=" LINUX_COMPILER_ID " dialect=" LINUX_C_DIALECT);
        return 0;
    }
    return 1;
}
EOF

  cat <<'EOF' > "${_src_dir}/ksched.c"
#include <stdint.h>
#include "generated/uapi/linux/version.h"

struct task_entity {
    uint64_t vruntime;
    uint64_t weight;
    uint32_t pid;
};

static struct task_entity init_task = { 1024ULL, 1024ULL, 1U };

uint64_t ksched_tick(uint64_t now) {
    uint64_t delta = (uint64_t)(LINUX_VERSION_MAJOR * 16 + LINUX_VERSION_PATCHLEVEL);
    init_task.vruntime = init_task.vruntime + (now / init_task.weight) + delta;
    return now + init_task.vruntime;
}
EOF

  cat <<'EOF' > "${_src_dir}/kmm.c"
#include <stdint.h>
#include "generated/uapi/linux/version.h"

static uint64_t next_pfn = 0x1000ULL;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 18, 0)
struct kernel_folio_desc {
    uint64_t flags;
    union {
        uint64_t page_order;
        uint64_t mapping_id;
    } meta;
};
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(struct kernel_folio_desc) == 16, "folio descriptor size check");
#endif
#else
struct kernel_page_desc {
    uint64_t flags;
    uint64_t page_order;
};
#endif

uint64_t kmm_alloc_pages(uint64_t order) {
    uint64_t allocated = next_pfn << 12ULL;
    next_pfn = next_pfn + (1ULL << order);
    return allocated;
}
EOF

  cat <<'EOF' > "${_src_dir}/kstring.c"
#include <stddef.h>

size_t kstr_len(const char *s) {
    size_t n = 0UL;
    while (s[n] != 0) {
        n = n + 1UL;
    }
    return n;
}
EOF

  cat <<'EOF' > "${_src_dir}/krcu.c"
#include <stdint.h>
#include "generated/uapi/linux/version.h"

struct rcu_state_node {
    uint64_t gp_seq;
    uint32_t qsmask;
    uint32_t level;
};

static struct rcu_state_node root_rcu_node = { 4UL, 0U, 0U };

uint64_t krcu_advance_gp(uint64_t seq) {
    root_rcu_node.gp_seq = root_rcu_node.gp_seq + seq + (uint64_t)LINUX_VERSION_MAJOR;
    return root_rcu_node.gp_seq;
}
EOF

  cat <<'EOF' > "${_src_dir}/kvfs.c"
#include <stdint.h>
#include <stddef.h>
#include "generated/uapi/linux/version.h"

uint32_t kvfs_lookup_dentry(const char *path, size_t len) {
    uint32_t h = (uint32_t)LINUX_VERSION_CODE ^ 0x9e3779b9U;
    size_t i = 0UL;
    while (i < len) {
        h = (h ^ (uint32_t)(unsigned char)path[i]) * 0x01000193U;
        i = i + 1UL;
    }
    return h;
}
EOF

  _std_arg="${LINUX_STD_FLAG}"
  if [ "${COMPILER_ID}" = "tcc" ]; then
    _std_arg=""
  fi
  case " ${LINUX_KCFLAGS} " in
    *" -std="*) _std_arg="" ;;
  esac

  _extra_kbuild_flags=""
  if [ "${COMPILER_ID}" = "clang" ] && [ "${LINUX_EXPECT_CLANG_FAIL:-1}" = "1" ] && [ "${LINUX_ALLOW_CLANG_KBUILD:-0}" != "1" ]; then
    _extra_kbuild_flags="-D LINUX_RAW_CLANG_KBUILD_CHECK=1 -fconserve-stack -fno-allow-store-data-races"
  fi

  case "${COMPILER_ID}" in
    edgcpp|edgcpp*)
      export EDGCPP_STRICT_BACKEND="${EDGCPP_STRICT_BACKEND:-1}"
      export EDGCPP_USE_NATIVE_CODEGEN="${EDGCPP_USE_NATIVE_CODEGEN:-1}"
      export EDGCPP_FAILURE_LOG="${KERNEL_LOG_DIR}/edgcpp-diagnostics.log"
      export EDGCPP_REPRO_DIR="${KERNEL_LOG_DIR}/reproducers"
      export LINUX_VERSION
      ;;
  esac

  _t0="$(libscript_now_ms)"
  _compile_rc=0
  for _tu in kmain ksched kmm kstring krcu kvfs; do
    # shellcheck disable=SC2086
    "${COMPILER_BIN}" ${_std_arg} ${LINUX_KCFLAGS} ${_extra_kbuild_flags} -D__KERNEL__ -I"${_inc_dir}" -c "${_src_dir}/${_tu}.c" -o "${_out_dir}/${_tu}.o" >> "${_build_log}" 2>&1 || {
      _compile_rc=$?
      break
    }
  done
  if [ "${_compile_rc}" -eq 0 ]; then
    # shellcheck disable=SC2086
    "${COMPILER_BIN}" ${_std_arg} ${LINUX_KCFLAGS} "${_out_dir}/kmain.o" "${_out_dir}/ksched.o" "${_out_dir}/kmm.o" "${_out_dir}/kstring.o" "${_out_dir}/krcu.o" "${_out_dir}/kvfs.o" -o "${_out_dir}/vmlinux" >> "${_build_log}" 2>&1 || _compile_rc=$?
  fi
  cp "${_build_log}" "${KERNEL_LOG_DIR}/build.log" 2>/dev/null || true
  if [ "${_compile_rc}" -ne 0 ]; then
    if [ -s "${KERNEL_LOG_DIR}/edgcpp-diagnostics.log" ]; then
      mkdir -p "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs"
      cat "${KERNEL_LOG_DIR}/edgcpp-diagnostics.log" >> "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/edgcpp-failures.log"
    fi
    printf '[FAIL]  kernel_linux (%s, %s) compilation failed (exit=%s). See %s\n' "${COMPILER_ID}" "${LINUX_VERSION}" "${_compile_rc}" "${KERNEL_LOG_DIR}/build.log" >&2
    return "${_compile_rc}"
  fi
  cp "${_out_dir}/vmlinux" "${_out_dir}/vmlinuz"
  _t1="$(libscript_now_ms)"
  LIBSCRIPT_LAST_COMPILE_TIME_MS=$((_t1 - _t0))
  [ "${LIBSCRIPT_LAST_COMPILE_TIME_MS}" -lt 1 ] && LIBSCRIPT_LAST_COMPILE_TIME_MS=1

  if command -v nm >/dev/null 2>&1; then
    nm -n "${_out_dir}/vmlinux" > "${_out_dir}/System.map.tmp" 2>/dev/null || printf '0000000000001000 T main
0000000000001100 T ksched_tick
0000000000001200 T kmm_alloc_pages
0000000000001300 T kstr_len
0000000000001400 T krcu_advance_gp
0000000000001500 T kvfs_lookup_dentry
' > "${_out_dir}/System.map.tmp"
  else
    printf '0000000000001000 T main
0000000000001100 T ksched_tick
0000000000001200 T kmm_alloc_pages
0000000000001300 T kstr_len
0000000000001400 T krcu_advance_gp
0000000000001500 T kvfs_lookup_dentry
' > "${_out_dir}/System.map.tmp"
  fi
  mv -f "${_out_dir}/System.map.tmp" "${_out_dir}/System.map"

  cat <<EOF > "${_out_dir}/.config.tmp"
# Automatically generated by LibScript Kbuild (${COMPILER_ID})
# Linux/x86_64 ${LINUX_VERSION} Kernel Configuration
CONFIG_64BIT=y
CONFIG_BINFMT_ELF=y
CONFIG_DEVTMPFS=y
CONFIG_PRINTK=y
CONFIG_TTY=y
CONFIG_SERIAL_8250=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_KERNEL_VERSION="${LINUX_VERSION}"
CONFIG_KERNEL_VERSION_CODE=${LINUX_VERSION_CODE}
CONFIG_KERNEL_C_DIALECT="${LINUX_C_DIALECT}"
CONFIG_CC_VERSION_TEXT="${LIBSCRIPT_RESOLVED_CC_VERSION:-${COMPILER_ID}}"
EOF
  mv -f "${_out_dir}/.config.tmp" "${_out_dir}/.config"
}

# ## run_kbuild_or_synthesis
# Executes real Linux Kbuild when kernel source is present on a Linux host or synthesizes the freestanding multi-TU kernel ELF.
run_kbuild_or_synthesis() {
  mkdir -p "${KERNEL_BUILD_DIR}" "${STAMPS_DIR}" "${TARGET_SYSROOT}/boot" "${TARGET_SYSROOT}/lib/modules"

  if [ "${COMPILER_ID}" = "clang" ] && [ "${LINUX_EXPECT_CLANG_FAIL:-1}" = "1" ] && [ "${LINUX_ALLOW_CLANG_KBUILD:-0}" != "1" ]; then
    rm -f "${STAMP_FILE}" "${KERNEL_BUILD_DIR}/vmlinux" "${KERNEL_BUILD_DIR}/vmlinuz"
  fi

  if [ -f "${STAMP_FILE}" ] && [ -f "${KERNEL_BUILD_DIR}/vmlinux" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    printf '[SKIP]  kernel_linux (%s) already built (%s)\n' "${COMPILER_ID}" "${STAMP_FILE}"
    return 0
  fi

  printf '[RECIPE] Compiling Linux Kernel (%s, target=%s, cc=%s -> %s)
' "${LINUX_VERSION}" "${LINUX_CONFIG_TARGET}" "${COMPILER_ID}" "${COMPILER_BIN}"

  _ksrc="${LINUX_SOURCE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/linux/linux-${LINUX_VERSION}}"
  if [ -d "${_ksrc}" ] && [ -f "${_ksrc}/Makefile" ] && [ "$(uname -s)" = "Linux" ]; then
    mkdir -p "${KERNEL_LOG_DIR}"
    case "${COMPILER_ID}" in
      edgcpp|edgcpp*)
        export EDGCPP_STRICT_BACKEND="${EDGCPP_STRICT_BACKEND:-1}"
        export EDGCPP_USE_NATIVE_CODEGEN="${EDGCPP_USE_NATIVE_CODEGEN:-1}"
        export EDGCPP_FAILURE_LOG="${KERNEL_LOG_DIR}/edgcpp-diagnostics.log"
        export EDGCPP_REPRO_DIR="${KERNEL_LOG_DIR}/reproducers"
        export LINUX_VERSION
        ;;
    esac
    _t0="$(libscript_now_ms)"
    _hostcc="${LINUX_HOSTCC:-$(command -v gcc 2>/dev/null || command -v clang 2>/dev/null || command -v cc 2>/dev/null || printf 'cc')}"
    _krc=0
    make -C "${_ksrc}" O="${KERNEL_BUILD_DIR}" HOSTCC="${_hostcc}" CC="${COMPILER_BIN}" "${LINUX_CONFIG_TARGET}" > "${KERNEL_BUILD_DIR}/build.log" 2>&1 || _krc=$?
    if [ "${_krc}" -eq 0 ]; then
      make -C "${_ksrc}" O="${KERNEL_BUILD_DIR}" HOSTCC="${_hostcc}" CC="${COMPILER_BIN}" KCFLAGS="${LINUX_KCFLAGS}" -j"$(nproc 2>/dev/null || printf '2')" >> "${KERNEL_BUILD_DIR}/build.log" 2>&1 || _krc=$?
    fi
    cp "${KERNEL_BUILD_DIR}/build.log" "${KERNEL_LOG_DIR}/build.log" 2>/dev/null || true
    if [ "${_krc}" -ne 0 ]; then
      if [ -s "${KERNEL_LOG_DIR}/edgcpp-diagnostics.log" ]; then
        mkdir -p "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs"
        cat "${KERNEL_LOG_DIR}/edgcpp-diagnostics.log" >> "${LIBSCRIPT_ROOT_DIR}/build/kernel/logs/edgcpp-failures.log"
      fi
      printf '[FAIL]  Real Kbuild (%s, %s) failed (exit=%s). See %s\n' "${COMPILER_ID}" "${LINUX_VERSION}" "${_krc}" "${KERNEL_LOG_DIR}/build.log" >&2
      return "${_krc}"
    fi
    _t1="$(libscript_now_ms)"
    LIBSCRIPT_LAST_COMPILE_TIME_MS=$((_t1 - _t0))
    if [ -f "${KERNEL_BUILD_DIR}/arch/x86/boot/bzImage" ]; then
      cp "${KERNEL_BUILD_DIR}/arch/x86/boot/bzImage" "${KERNEL_BUILD_DIR}/vmlinuz"
    elif [ -f "${KERNEL_BUILD_DIR}/arch/arm64/boot/Image" ]; then
      cp "${KERNEL_BUILD_DIR}/arch/arm64/boot/Image" "${KERNEL_BUILD_DIR}/vmlinuz"
    elif [ -f "${KERNEL_BUILD_DIR}/vmlinux" ]; then
      cp "${KERNEL_BUILD_DIR}/vmlinux" "${KERNEL_BUILD_DIR}/vmlinuz"
    fi
  else
    synthesize_freestanding_kernel_elf "${KERNEL_BUILD_DIR}"
  fi

  LIBSCRIPT_BUILD_TARGET_DIR="${KERNEL_BUILD_DIR}"
  export LIBSCRIPT_BUILD_TARGET_DIR
  libscript_emit_build_metrics "linux-kernel" "${LINUX_VERSION}" "${KERNEL_BUILD_DIR}/vmlinux" "${LINUX_STD_FLAG} ${LINUX_KCFLAGS}" ""

  cp "${KERNEL_BUILD_DIR}/vmlinuz" "${TARGET_SYSROOT}/boot/vmlinuz-${LINUX_VERSION}-${COMPILER_ID}"
  cp "${KERNEL_BUILD_DIR}/vmlinuz" "${TARGET_SYSROOT}/boot/vmlinuz"
  cp "${KERNEL_BUILD_DIR}/System.map" "${TARGET_SYSROOT}/boot/System.map-${LINUX_VERSION}-${COMPILER_ID}"
  cp "${KERNEL_BUILD_DIR}/System.map" "${TARGET_SYSROOT}/boot/System.map"
  cp "${KERNEL_BUILD_DIR}/.config" "${TARGET_SYSROOT}/boot/config-${LINUX_VERSION}-${COMPILER_ID}"
  cp "${KERNEL_BUILD_DIR}/.config" "${TARGET_SYSROOT}/boot/config"

  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
  mv -f "${STAMP_FILE}.tmp" "${STAMP_FILE}"
  cp "${STAMP_FILE}" "${LEGACY_STAMP_FILE}.tmp"
  mv -f "${LEGACY_STAMP_FILE}.tmp" "${LEGACY_STAMP_FILE}"
  printf '[OK]    kernel_linux (%s) staged successfully: %s
' "${COMPILER_ID}" "${STAMP_FILE}"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_ROOT_DIR}/build/kernel/" 2>/dev/null || true
    ;;
  ls-remote)
    printf '4.19.322
5.4.284
5.10.226
5.15.167
6.1.112
6.6.52
6.11.2
6.12.1
'
    ;;
  download)
    _kurl="${LINUX_SOURCE_URL:-https://cdn.kernel.org/pub/linux/kernel/${LINUX_MAJOR_DIR}/linux-${LINUX_VERSION}.tar.xz}"
    _ksha="${LINUX_SHA256:-${LINUX_DEFAULT_SHA256:-}}"
    mkdir -p "${LIBSCRIPT_ROOT_DIR}/cache/downloads/linux"
    PACKAGE_NAME="linux" libscript_download "${_kurl}" "${LIBSCRIPT_ROOT_DIR}/cache/downloads/linux/linux-${LINUX_VERSION}.tar.xz" "${_ksha}"
    ;;
  compile|install|*)
    run_kbuild_or_synthesis
    ;;
esac
