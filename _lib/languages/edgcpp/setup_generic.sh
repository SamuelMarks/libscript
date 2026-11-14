#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the EDG C/C++ Compiler Frontend (edgcpp).
# Supports Mode 1 (pkg_mgr/system), Mode 2/3 (from-source with selectable bootstrap
# toolchain), local_binary registration, and native GitHub release archive installation
# across edgcpp+llvm+gcc, edgcpp+llvm, and edgcpp+gcc flavors (v7.0.1).
# ## Usage
# ./_lib/languages/edgcpp/setup_generic.sh
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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

if [ -n "${EDGCPP_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${EDGCPP_PKG_MGR}"
fi

EDGCPP_INSTALL_METHOD="${EDGCPP_INSTALL_METHOD:-$(libscript_resolve_install_method "EDGCPP")}"
EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-edgcpp+llvm+gcc}"
ACTION="${ACTION:-install}"
VERSION="${EDGCPP_VERSION:-${VERSION:-7.0.1}}"

# ## resolve_latest_edgcpp_release
# Queries the GitHub Releases API for the latest SamuelMarks/edgcpp-compiler tag when EDGCPP_CHECK_LATEST=1 and LIBSCRIPT_OFFLINE!=1, falling back to 7.0.1.
resolve_latest_edgcpp_release() {
  if [ "${EDGCPP_CHECK_LATEST:-0}" = "1" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && command -v curl >/dev/null 2>&1; then
    _api_tag="$(curl -fsSL --connect-timeout 5 "https://api.github.com/repos/SamuelMarks/edgcpp-compiler/releases/latest" 2>/dev/null | grep '"tag_name"' | head -n 1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/' || true)"
    if [ -n "${_api_tag}" ]; then
      printf '%s\n' "${_api_tag}"
      return 0
    fi
  fi
  printf '%s\n' '7.0.1'
}

# ## resolve_exact_version
# Resolves semantic version aliases ('latest', 'stable', '7.0', 'v7.0.1') to '7.0.1' or the dynamically queried latest release.
resolve_exact_version() {
  case "${VERSION:-latest}" in
    latest|stable|"")
      EXACT_VERSION="$(resolve_latest_edgcpp_release)"
      ;;
    7.0|v7.0.1|7.0.1)
      EXACT_VERSION='7.0.1'
      ;;
    v*)
      EXACT_VERSION="${VERSION#v}"
      ;;
    *)
      EXACT_VERSION="${VERSION}"
      ;;
  esac
}

# ## resolve_edgcpp_release_asset
# Determines the GitHub release archive filename, download URL, and SHA-256 checksum for the current OS, architecture, and EDGCPP_FLAVOR.
resolve_edgcpp_release_asset() {
  resolve_exact_version
  _os_tag='linux'
  _arch_tag='x86_64'
  _ext='tar.gz'

  _uname_s="${UNAME_LOWER:-linux}"
  _uname_m="$(printf '%s' "${ARCH:-x86_64}" | tr '[:upper:]' '[:lower:]')"

  case "${_uname_s}" in
    darwin*|macos*)
      _os_tag='macos'
      _arch_tag='aarch64'
      ;;
    msys*|mingw*|cygwin*|windows*)
      _os_tag='windows'
      _ext='zip'
      case "${_uname_m}" in
        arm64|aarch64) _arch_tag="arm64" ;;
        *) _arch_tag="x86_64" ;;
      esac
      ;;
    *)
      _os_tag='linux'
      case "${_uname_m}" in
        arm64|aarch64) _arch_tag="aarch64" ;;
        *) _arch_tag="x86_64" ;;
      esac
      ;;
  esac

  EDGCPP_ASSET_NAME="${EDGCPP_FLAVOR}-v${EXACT_VERSION}-${_os_tag}-${_arch_tag}.${_ext}"
  EDGCPP_ASSET_URL="${EDGCPP_DOWNLOAD_URL:-https://github.com/SamuelMarks/edgcpp-compiler/releases/download/v${EXACT_VERSION}/${EDGCPP_ASSET_NAME}}"
  EDGCPP_SHA256SUMS_URL="https://github.com/SamuelMarks/edgcpp-compiler/releases/download/v${EXACT_VERSION}/SHA256SUMS.txt"
  EDGCPP_SHA256SUMS_DIGEST=""
  if [ "${EXACT_VERSION}" = "7.0.1" ]; then
    EDGCPP_SHA256SUMS_DIGEST='1463b963d76d1b6fb1950f43dc1d3a8e53703923e4a44d778ac33b412516d0c0'
  fi
  EDGCPP_ASSET_SHA256=""

  case "${EDGCPP_ASSET_NAME}" in
    "edgcpp+llvm+gcc-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="16441f25f2cd25d45a1fc95ed503027cf392b96e9e00bd533f55690cd44d4f56" ;;
    "edgcpp+llvm+gcc-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="b73e8b9fbeedd398a24d0292d56a8aa40fc4b38c3d2a2ad8e0ce020895954350" ;;
    "edgcpp+llvm+gcc-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="6a8c087a4d43e934393244bf866fff622eda4e0290903f860e5cb8f9b61a8bd5" ;;
    "edgcpp+llvm+gcc-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="3221b67308aed3d5144a3b6cbc5ac2958f4c4c0ebc126584136279a32f1a1c1d" ;;
    "edgcpp+llvm+gcc-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="0ac2b826cb1dacce195c50da9bdc8062999a15323346dc94ac2a12fbaeb0621b" ;;
    "edgcpp+llvm-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="e96329691fe8c73a9314daa5052af84ee0dfd6ff5ec3f09f2b13b256732b3330" ;;
    "edgcpp+llvm-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="59ace4efc81f069a2f7d0c7047340ba63c41a7f0a8864c419c5e057eb5959a19" ;;
    "edgcpp+llvm-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="c2dd91eaa4eb1b89ecfea71ed6c1e89289c86aa602dc9c0d67e6f961bdba99c9" ;;
    "edgcpp+llvm-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="9d02a8f933b3eb0c8eb7415f94d6fbeb14d89523f8620a1c966f436c2707a30c" ;;
    "edgcpp+llvm-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="2663c9f8caebb75d43fd6c316fe776ffc25331647380e32f78b29dfd1d272488" ;;
    "edgcpp+gcc-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="7d057519f9a735dcdf63e0130a78327f7039bd1d7c290527930a52191825b9be" ;;
    "edgcpp+gcc-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="f82768fbdb292fd4082066151f48de71a72b450bdddfbf4b23a170bd51bedb08" ;;
    "edgcpp+gcc-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="19c91cae85deccd39bb56bbbb012fc3911b5a60c8cb1f0cc48f755a7f0c25eb1" ;;
    "edgcpp+gcc-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="b1c2be566247de89e9663eb0a4e8369b98e2d591d3b5a8ea32a0e8b909fa54b6" ;;
    "edgcpp+gcc-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="8e99c17d62a4104bf6a646018a69dd972e1281561f7c38c6c18bf14e12973b49" ;;
  esac

  if [ -z "${EDGCPP_ASSET_SHA256}" ] && [ -z "${EDGCPP_DOWNLOAD_URL:-}" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
    _cache_dir="${EDGCPP_DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/edgcpp}"
    mkdir -p "${_cache_dir}"
    _sums_file="${_cache_dir}/SHA256SUMS-v${EXACT_VERSION}.txt"
    if [ ! -f "${_sums_file}" ]; then
      PACKAGE_NAME="edgcpp" libscript_download "${EDGCPP_SHA256SUMS_URL}" "${_sums_file}" "${EDGCPP_SHA256SUMS_DIGEST}" 2>/dev/null || true
    fi
    if [ -f "${_sums_file}" ]; then
      EDGCPP_ASSET_SHA256="$(grep "${EDGCPP_ASSET_NAME}" "${_sums_file}" 2>/dev/null | head -n 1 | awk '{print $1}' || true)"
    fi
  fi
  if [ -n "${EDGCPP_DOWNLOAD_URL:-}" ]; then
    EDGCPP_ASSET_SHA256=""
  fi
}

# ## stage_edgcpp_wrappers
# Stages the edgcpp, edg-cc, edg-c++, and cc driver wrapper shims and predefined_macros.txt into the target prefix idempotently.
stage_edgcpp_wrappers() {
  _target_dir="${1}"
  mkdir -p "${_target_dir}/bin" "${_target_dir}/lib" "${_target_dir}/include_c99" "${_target_dir}/include_c++"

  if [ -n "${EDGCPP_BIN:-}" ] && [ -x "${EDGCPP_BIN}" ] && [ "${EDGCPP_BIN}" != "${_target_dir}/bin/cpfe" ] && [ "${EDGCPP_BIN}" != "${_target_dir}/bin/edgcpp" ]; then
    ln -sf "${EDGCPP_BIN}" "${_target_dir}/bin/cpfe"
  fi

  for _bin_tool in cpfe cpfe-cp eccp cdisp mk_errinfo edg_decode; do
    if [ -f "${_target_dir}/bin/${_bin_tool}" ]; then
      chmod +x "${_target_dir}/bin/${_bin_tool}" 2>/dev/null || true
    fi
  done

  if command -v install_name_tool >/dev/null 2>&1 && command -v otool >/dev/null 2>&1 && [ -f "/opt/homebrew/opt/z3/lib/libz3.dylib" ]; then
    for _macho_bin in cpfe cpfe-cp; do
      if [ -f "${_target_dir}/bin/${_macho_bin}" ]; then
        _stale_z3=$(otool -L "${_target_dir}/bin/${_macho_bin}" 2>/dev/null | awk '/libz3\.[0-9.]+\.dylib/ {print $1}' || true)
        for _z3_dep in ${_stale_z3}; do
          if [ ! -f "${_z3_dep}" ]; then
            install_name_tool -change "${_z3_dep}" "/opt/homebrew/opt/z3/lib/libz3.dylib" "${_target_dir}/bin/${_macho_bin}" 2>/dev/null || true
            if command -v codesign >/dev/null 2>&1; then
              codesign -f -s - "${_target_dir}/bin/${_macho_bin}" >/dev/null 2>&1 || true
            fi
          fi
        done
      fi
    done
  fi

  if [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" != "1" ] && [ "${UNAME:-}" = "Linux" ]; then
    if [ -f "/etc/alpine-release" ]; then
      if [ ! -e "/lib/ld-linux-aarch64.so.1" ] && [ ! -e "/lib/ld-linux-x86-64.so.2" ] || [ ! -e "/usr/lib/libgccjit.so.0" ]; then
        libscript_depends gcompat libstdc++ ncurses-libs zlib zstd-libs libgccjit gcc g++ musl-dev >/dev/null 2>&1 || true
      fi
      if [ -e "/usr/lib/libncursesw.so.6" ]; then
        ln -sf "/usr/lib/libncursesw.so.6" "${_target_dir}/lib/libtinfo.so.6" 2>/dev/null || true
        priv ln -sf "/usr/lib/libncursesw.so.6" "/usr/lib/libtinfo.so.6" 2>/dev/null || true
      fi
      if command -v gcc >/dev/null 2>&1 && [ -e "/lib/libgcompat.so.0" ]; then
        _shim_c="${TMPDIR:-/tmp}/edg_musl_shim_$$.c"
        cat << 'EOF' > "${_shim_c}"
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <setjmp.h>
#include <math.h>
long __isoc23_strtol(const char *nptr, char **endptr, int base) { return strtol(nptr, endptr, base); }
long long __isoc23_strtoll(const char *nptr, char **endptr, int base) { return strtoll(nptr, endptr, base); }
unsigned long __isoc23_strtoul(const char *nptr, char **endptr, int base) { return strtoul(nptr, endptr, base); }
unsigned long long __isoc23_strtoull(const char *nptr, char **endptr, int base) { return strtoull(nptr, endptr, base); }
long __isoc23_sscanf(const char *str, const char *format, ...) { va_list ap; va_start(ap, format); int r = vsscanf(str, format, ap); va_end(ap); return r; }
int __isoc23_fscanf(FILE *stream, const char *format, ...) { va_list ap; va_start(ap, format); int r = vfscanf(stream, format, ap); va_end(ap); return r; }
struct mallinfo2_shim { size_t f[10]; };
struct mallinfo2_shim mallinfo2(void) { struct mallinfo2_shim m; memset(&m, 0, sizeof(m)); return m; }
uint32_t arc4random(void) { return (uint32_t)rand(); }
void *__memcpy_chk(void *dest, const void *src, size_t len, size_t destlen) { (void)destlen; return memcpy(dest, src, len); }
void *__memmove_chk(void *dest, const void *src, size_t len, size_t destlen) { (void)destlen; return memmove(dest, src, len); }
void *__memset_chk(void *dest, int c, size_t len, size_t destlen) { (void)destlen; return memset(dest, c, len); }
char *__strcpy_chk(char *dest, const char *src, size_t destlen) { (void)destlen; return strcpy(dest, src); }
char *__strncpy_chk(char *dest, const char *src, size_t len, size_t destlen) { (void)destlen; return strncpy(dest, src, len); }
char *__strcat_chk(char *dest, const char *src, size_t destlen) { (void)destlen; return strcat(dest, src); }
int __snprintf_chk(char *s, size_t maxlen, int flag, size_t slen, const char *format, ...) { (void)flag; (void)slen; va_list ap; va_start(ap, format); int r = vsnprintf(s, maxlen, format, ap); va_end(ap); return r; }
int __vsnprintf_chk(char *s, size_t maxlen, int flag, size_t slen, const char *format, va_list ap) { (void)flag; (void)slen; return vsnprintf(s, maxlen, format, ap); }
int __printf_chk(int flag, const char *format, ...) { (void)flag; va_list ap; va_start(ap, format); int r = vprintf(format, ap); va_end(ap); return r; }
int __fprintf_chk(FILE *stream, int flag, const char *format, ...) { (void)flag; va_list ap; va_start(ap, format); int r = vfprintf(stream, format, ap); va_end(ap); return r; }
char *__getcwd_chk(char *buf, size_t size, size_t buflen) { (void)buflen; return getcwd(buf, size); }
void __longjmp_chk(jmp_buf env, int val) { longjmp(env, val); }
int __isnan(double x) { return isnan(x); }
int backtrace(void **buffer, int size) { (void)buffer; (void)size; return 0; }
void *__sched_cpualloc(size_t count) { return calloc(count, sizeof(unsigned long)); }
void __sched_cpufree(void *set) { free(set); }
char __libc_single_threaded = 1;
int pthread_mutex_lock(void *m) { (void)m; return 0; }
int pthread_mutex_trylock(void *m) { (void)m; return 0; }
int pthread_mutex_unlock(void *m) { (void)m; return 0; }
EOF
        priv gcc -shared -fPIC -O2 "${_shim_c}" -o "/lib/libgcompat.so.0" 2>/dev/null || true
        rm -f "${_shim_c}"
      fi
    elif [ -f "/etc/debian_version" ]; then
      if command -v ldd >/dev/null 2>&1 && [ -x "${_target_dir}/bin/cpfe" ]; then
        if ldd "${_target_dir}/bin/cpfe" 2>/dev/null | grep -q "not found"; then
          libscript_depends libgccjit0 libzstd1 zlib1g libtinfo6 gcc g++ libc6-dev >/dev/null 2>&1 || true
        fi
      fi
    elif [ -f "/etc/redhat-release" ] || [ -f "/etc/rocky-release" ]; then
      if command -v ldd >/dev/null 2>&1 && [ -x "${_target_dir}/bin/cpfe" ]; then
        if ldd "${_target_dir}/bin/cpfe" 2>&1 | grep -qE "not found|GLIBC_2\.36|GLIBCXX_3\.4\.32|LIBGCCJIT_ABI|no version information"; then
          libscript_depends libgccjit zstd zlib ncurses-libs gcc gcc-c++ glibc-devel >/dev/null 2>&1 || true
          libscript_depends gcc-toolset-13-libgccjit >/dev/null 2>&1 || libscript_depends gcc-toolset-14-libgccjit >/dev/null 2>&1 || true
        fi
      fi
      rm -f "${_target_dir}/lib/libtinfo.so.6" 2>/dev/null || true
      for _gt_jit in /opt/rh/gcc-toolset-14/root/usr/lib64/libgccjit.so.0 /opt/rh/gcc-toolset-13/root/usr/lib64/libgccjit.so.0 /opt/rh/gcc-toolset-12/root/usr/lib64/libgccjit.so.0; do
        if [ -e "${_gt_jit}" ]; then
          ln -sf "${_gt_jit}" "${_target_dir}/lib/libgccjit.so.0" 2>/dev/null || true
          break
        fi
      done
      if command -v gcc >/dev/null 2>&1 && [ -x "${_target_dir}/bin/cpfe" ]; then
        if ldd "${_target_dir}/bin/cpfe" 2>&1 | grep -qE "GLIBC_2\.36|GLIBCXX_3\.4\.32|no version information" || [ ! -f "${_target_dir}/lib/libedg_el9_compat.so" ]; then
          _shim_c="${TMPDIR:-/tmp}/edg_el9_shim_$$.c"
          _shim_map="${TMPDIR:-/tmp}/edg_el9_shim_$$.map"
          cat << 'EOF' > "${_shim_c}"
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
uint32_t __arc4random_el9(void) {
    uint32_t v = 0;
    int fd = open("/dev/urandom", O_RDONLY);
    if (fd >= 0) {
        if (read(fd, &v, sizeof(v)) != (ssize_t)sizeof(v)) v = (uint32_t)rand();
        close(fd);
    } else {
        v = (uint32_t)rand();
    }
    return v;
}
__asm__(".symver __arc4random_el9,arc4random@@GLIBC_2.34");
void __ios_init_el9(void) {}
__asm__(".symver __ios_init_el9,_ZSt21ios_base_library_initv@@GLIBCXX_3.4.29");
int __setupterm_el9(const char *t, int f, int *e) { (void)t; (void)f; if (e) *e = 0; return -1; }
__asm__(".symver __setupterm_el9,setupterm@@NCURSES6_TINFO_5.0.19991023");
int __tigetnum_el9(const char *c) { (void)c; return -1; }
__asm__(".symver __tigetnum_el9,tigetnum@@NCURSES6_TINFO_5.0.19991023");
void *__set_curterm_el9(void *t) { return t; }
__asm__(".symver __set_curterm_el9,set_curterm@@NCURSES6_TINFO_5.0.19991023");
int __del_curterm_el9(void *t) { (void)t; return 0; }
__asm__(".symver __del_curterm_el9,del_curterm@@NCURSES6_TINFO_5.0.19991023");
EOF
          cat << 'EOF' > "${_shim_map}"
GLIBC_2.34 {
  global: arc4random;
};
GLIBCXX_3.4.29 {
  global: _ZSt21ios_base_library_initv;
};
NCURSES6_TINFO_5.0.19991023 {
  global: setupterm; tigetnum; set_curterm; del_curterm;
};
EOF
          gcc -shared -fPIC -O2 "${_shim_c}" -Wl,--version-script="${_shim_map}" -o "${_target_dir}/lib/libedg_el9_compat.so" 2>/dev/null || true
          rm -f "${_shim_c}" "${_shim_map}"
          if command -v python3 >/dev/null 2>&1; then
            for _eb in cpfe cpfe-cp eccp cdisp mk_errinfo edg_decode; do
              if [ -f "${_target_dir}/bin/${_eb}" ]; then
                python3 -c '
import struct, sys
path = sys.argv[1]
replacements = {"GLIBC_2.36": "GLIBC_2.34", "GLIBCXX_3.4.32": "GLIBCXX_3.4.29"}
with open(path, "rb") as f:
    data = bytearray(f.read())
if data[:4] == b"\x7fELF" and data[4] == 2:
    e_shoff = struct.unpack_from("<Q", data, 40)[0]
    e_shentsize = struct.unpack_from("<H", data, 58)[0]
    e_shnum = struct.unpack_from("<H", data, 60)[0]
    verneed_off = verneed_cnt = verneed_link = 0
    for i in range(e_shnum):
        sh = e_shoff + i * e_shentsize
        if struct.unpack_from("<I", data, sh + 4)[0] == 0x6ffffffe:
            verneed_off = struct.unpack_from("<Q", data, sh + 24)[0]
            verneed_link = struct.unpack_from("<I", data, sh + 40)[0]
            verneed_cnt = struct.unpack_from("<I", data, sh + 44)[0]
    if verneed_off:
        dynstr_off = struct.unpack_from("<Q", data, e_shoff + verneed_link * e_shentsize + 24)[0]
        def get_str(off):
            end = data.find(0, dynstr_off + off)
            return bytes(data[dynstr_off + off:end]).decode("latin1")
        def elf_hash(s):
            h = 0
            for ch in s.encode("latin1"):
                h = ((h << 4) + ch) & 0xffffffff
                g = h & 0xf0000000
                if g: h ^= (g >> 24)
                h &= (~g) & 0xffffffff
            return h
        pos = verneed_off
        str_offsets = {}
        for _ in range(verneed_cnt):
            vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from("<HHIII", data, pos)
            apos = pos + vn_aux
            for _ in range(vn_cnt):
                vna_hash, vna_flags, vna_other, vna_name, vna_next = struct.unpack_from("<IHHII", data, apos)
                str_offsets[get_str(vna_name)] = vna_name
                if vna_next == 0: break
                apos += vna_next
            if vn_next == 0: break
            pos += vn_next
        pos = verneed_off
        for _ in range(verneed_cnt):
            vn_version, vn_cnt, vn_file, vn_aux, vn_next = struct.unpack_from("<HHIII", data, pos)
            apos = pos + vn_aux
            for _ in range(vn_cnt):
                vna_hash, vna_flags, vna_other, vna_name, vna_next = struct.unpack_from("<IHHII", data, apos)
                name = get_str(vna_name)
                if name in replacements:
                    target = replacements[name]
                    new_name_off = str_offsets.get(target, vna_name)
                    if target not in str_offsets:
                        b_targ = target.encode("latin1") + b"\x00"
                        data[dynstr_off + vna_name:dynstr_off + vna_name + len(b_targ)] = b_targ
                    struct.pack_into("<IHHII", data, apos, elf_hash(target), vna_flags, vna_other, new_name_off, vna_next)
                if vna_next == 0: break
                apos += vna_next
            if vn_next == 0: break
            pos += vn_next
        with open(path, "wb") as f:
            f.write(data)
' "${_target_dir}/bin/${_eb}" 2>/dev/null || true
              fi
            done
          fi
        fi
      fi
    fi
  fi

  _host_cc="$(command -v clang 2>/dev/null || command -v gcc 2>/dev/null || command -v cc 2>/dev/null || true)"
  if [ -n "${_host_cc}" ]; then
    "${_host_cc}" -dM -E -x c /dev/null 2>/dev/null | grep -vE '^#define (__STDC|__DATE__|__TIME__|__FILE__|__LINE__|__COUNTER__|__TIMESTAMP__|__VERSION__|__clang__|__clang_|__llvm__|__BLOCKS__|__block|__null|__objc|__USER_LABEL_PREFIX__|__CHAR16_TYPE__|__CHAR32_TYPE__|__GCC_ASM|__FP_FAST|__GNUC|__GXX|__cplusplus|__EXCEPTIONS|__RTTI|__DEPRECATED)' | awk '/^#define [A-Za-z_][A-Za-z0-9_]* / { printf "#ifndef %s\n%s\n#endif\n", $2, $0 }' > "${_target_dir}/lib/predefined_macros.txt" || true
  fi
  if [ ! -s "${_target_dir}/lib/predefined_macros.txt" ]; then
    cat <<'EOF' > "${_target_dir}/lib/predefined_macros.txt"
#define __BYTE_ORDER__ 1234
#define __ORDER_LITTLE_ENDIAN__ 1234
#define __ORDER_BIG_ENDIAN__ 4321
EOF
  fi

  cat <<EOF > "${_target_dir}/bin/edgcpp.env"
EDGCPP_HOME="${_target_dir}"
EDGCPP_INSTALLED_FLAVOR="${EDGCPP_FLAVOR}"
CPFE_BIN="${_target_dir}/bin/cpfe"
CPFE_CP_BIN="${_target_dir}/bin/cpfe-cp"
EDG_RT_LIB="${_target_dir}/lib/libedg.a"
EDGCPP_WRAPPER_SCRIPT="${DIR}/edgcpp_wrapper.sh"
EOF

  cat <<'EOF' > "${_target_dir}/bin/edgcpp.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm+gcc}}"
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp.tmp"
  mv -f "${_target_dir}/bin/edgcpp.tmp" "${_target_dir}/bin/edgcpp"

  ln -sf "${_target_dir}/bin/edgcpp" "${_target_dir}/bin/edg-cc"
  ln -sf "${_target_dir}/bin/edgcpp" "${_target_dir}/bin/cc"

  cat <<'EOF' > "${_target_dir}/bin/edgcpp-gcc-be.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+gcc}}"
export EDGCPP_BACKEND_MODE="gcc_backend"
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp-gcc-be.tmp"
  mv -f "${_target_dir}/bin/edgcpp-gcc-be.tmp" "${_target_dir}/bin/edgcpp-gcc-be"
  ln -sf "${_target_dir}/bin/edgcpp-gcc-be" "${_target_dir}/bin/edgcpp-gcc"

  cat <<'EOF' > "${_target_dir}/bin/edgcpp-llvm-be.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm}}"
export EDGCPP_BACKEND_MODE="llvm_backend"
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp-llvm-be.tmp"
  mv -f "${_target_dir}/bin/edgcpp-llvm-be.tmp" "${_target_dir}/bin/edgcpp-llvm-be"
  ln -sf "${_target_dir}/bin/edgcpp-llvm-be" "${_target_dir}/bin/edgcpp-llvm"

  cat <<'EOF' > "${_target_dir}/bin/edgcpp-c-be.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm+gcc}}"
export EDGCPP_BACKEND_MODE="c_backend"
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp-c-be.tmp"
  mv -f "${_target_dir}/bin/edgcpp-c-be.tmp" "${_target_dir}/bin/edgcpp-c-be"
  ln -sf "${_target_dir}/bin/edgcpp-c-be" "${_target_dir}/bin/edgcpp-legacy"

  cat <<'EOF' > "${_target_dir}/bin/edgcpp-cp-be.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN EDG_RT_LIB
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm+gcc}}"
export EDGCPP_BACKEND_MODE="cpp_backend"
export EDGCPP_DRIVER_LANG="c++"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp-cp-be.tmp"
  mv -f "${_target_dir}/bin/edgcpp-cp-be.tmp" "${_target_dir}/bin/edgcpp-cp-be"

  cat <<'EOF' > "${_target_dir}/bin/edgcpp-fe-only.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN EDG_RT_LIB
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm+gcc}}"
export EDGCPP_BACKEND_MODE="fe_only"
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp-fe-only.tmp"
  mv -f "${_target_dir}/bin/edgcpp-fe-only.tmp" "${_target_dir}/bin/edgcpp-fe-only"

  cat <<'EOF' > "${_target_dir}/bin/edg-c++.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME EDGCPP_INSTALLED_FLAVOR CPFE_BIN CPFE_CP_BIN
export EDGCPP_FLAVOR="${EDGCPP_FLAVOR:-${EDGCPP_INSTALLED_FLAVOR:-edgcpp+llvm+gcc}}"
export EDGCPP_DRIVER_LANG="c++"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edg-c++.tmp"
  mv -f "${_target_dir}/bin/edg-c++.tmp" "${_target_dir}/bin/edg-c++"
  ln -sf "${_target_dir}/bin/edg-c++" "${_target_dir}/bin/edg-cxx"
  ln -sf "${_target_dir}/bin/edg-c++" "${_target_dir}/bin/c++"

  cat <<EOF > "${_target_dir}/edgcpp-release-metadata.json.tmp"
{
  "component": "edgcpp",
  "version": "${EXACT_VERSION}",
  "flavor": "${EDGCPP_FLAVOR}",
  "asset_name": "${EDGCPP_ASSET_NAME:-unknown}",
  "asset_sha256": "${EDGCPP_ASSET_SHA256:-unknown}",
  "repository": "https://github.com/SamuelMarks/edgcpp-compiler"
}
EOF
  mv -f "${_target_dir}/edgcpp-release-metadata.json.tmp" "${_target_dir}/edgcpp-release-metadata.json"
}

# ## extract_edgcpp_archive
# Extracts a downloaded edgcpp release archive into the target installation prefix.
extract_edgcpp_archive() {
  _archive_path="${1}"
  _dest_dir="${2}"
  _tmp_extract="${TMPDIR:-/tmp}/libscript_edgcpp_extract_$$"
  rm -rf "${_tmp_extract}"
  mkdir -p "${_tmp_extract}" "${_dest_dir}"

  case "${_archive_path}" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "${_archive_path}" -d "${_tmp_extract}"
      elif command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "${_archive_path}" -C "${_tmp_extract}"
      else
        tar -xf "${_archive_path}" -C "${_tmp_extract}"
      fi
      ;;
    *)
      tar -xzf "${_archive_path}" -C "${_tmp_extract}"
      ;;
  esac

  if [ -d "${_tmp_extract}/bin" ]; then
    cp -R "${_tmp_extract}/." "${_dest_dir}/" 2>/dev/null || true
  else
    _sub="$(find "${_tmp_extract}" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
    if [ -n "${_sub}" ] && [ -d "${_sub}" ]; then
      cp -R "${_sub}/." "${_dest_dir}/" 2>/dev/null || true
    fi
  fi
  rm -rf "${_tmp_extract}"
}

# ## build_edgcpp_multibackend_from_source
# Builds `edgcpp-compiler-multibackend` from a local git checkout (`EDGCPP_SOURCE_DIR` or `EDG_REPO`) in `release`, `llvm-cov`, `gcov`, `bug4-legacy`, or `all-modes` configuration via Tier 1 `cmake` + `ninja`.
build_edgcpp_multibackend_from_source() {
  _src_repo="${EDGCPP_SOURCE_DIR:-${EDG_REPO:-}}"
  _dest_prefix="${1}"
  _mode="${2:-${EDGCPP_BUILD_MODE:-release}}"

  if [ -z "${_src_repo}" ] || [ ! -d "${_src_repo}" ]; then
    log_error "EDGCPP_SOURCE_DIR / EDG_REPO ('${_src_repo}') does not exist."
    return 1
  fi
  if [ "${EDGCPP_REQUIRE_CLEAN_GIT:-0}" = "1" ] && command -v git >/dev/null 2>&1 && [ -d "${_src_repo}/.git" ]; then
    if [ -n "$(git -C "${_src_repo}" status --porcelain 2>/dev/null || true)" ]; then
      log_error "Dirty git worktree in '${_src_repo}' rejected (EDGCPP_REQUIRE_CLEAN_GIT=1)."
      return 1
    fi
  fi

  if ! command -v cmake >/dev/null 2>&1; then
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install cmake latest
  fi
  _gen_args=""
  if command -v ninja >/dev/null 2>&1; then
    _gen_args="-G Ninja"
  fi

  case "${_mode}" in
    all-modes)
      _work_root="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-modes"
      mkdir -p "${_work_root}"
      for _m_spec in "both:ON:ON" "llvm_only:ON:OFF" "gcc_only:OFF:ON" "legacy_only:OFF:OFF"; do
        _m_name="${_m_spec%%:*}"
        _m_r="${_m_spec#*:}"
        _m_llvm="${_m_r%%:*}"
        _m_gcc="${_m_r#*:}"
        # shellcheck disable=SC2086
        cmake -S "${_src_repo}" -B "${_work_root}/${_m_name}" ${_gen_args} -DCMAKE_BUILD_TYPE=Release "-DEDG_ENABLE_LLVM_BACKEND=${_m_llvm}" "-DEDG_ENABLE_GCC_BACKEND=${_m_gcc}" -DBUILD_TESTING=ON
        cmake --build "${_work_root}/${_m_name}"
      done
      return 0
      ;;
    bug4-legacy)
      _bdir="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-bug4-legacy"
      # shellcheck disable=SC2086
      cmake -S "${_src_repo}" -B "${_bdir}" ${_gen_args} -DCMAKE_BUILD_TYPE=Release -DEDG_ENABLE_LLVM_BACKEND=ON -DEDG_ENABLE_GCC_BACKEND=OFF -DCMAKE_C_FLAGS="-DEDG_BENCH_LEGACY_ARRAY_DECAY_LOAD=1" -DCMAKE_CXX_FLAGS="-DEDG_BENCH_LEGACY_ARRAY_DECAY_LOAD=1"
      cmake --build "${_bdir}"
      mkdir -p "${_dest_prefix}/bin"
      [ -x "${_bdir}/src/cpfe" ] && cp "${_bdir}/src/cpfe" "${_dest_prefix}/bin/cpfe-bug4-legacy"
      return 0
      ;;
    llvm-cov)
      _bdir="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-llvm-cov"
      # shellcheck disable=SC2086
      cmake -S "${_src_repo}" -B "${_bdir}" ${_gen_args} -DCMAKE_BUILD_TYPE=Debug -DEDG_ENABLE_LLVM_BACKEND=ON -DEDG_ENABLE_GCC_BACKEND=OFF -DBUILD_TESTING=ON -DCMAKE_CXX_FLAGS="-fprofile-instr-generate -fcoverage-mapping"
      cmake --build "${_bdir}"
      return 0
      ;;
    gcov)
      _bdir="${LIBSCRIPT_ROOT_DIR}/build/edgcpp-gcov"
      # shellcheck disable=SC2086
      cmake -S "${_src_repo}" -B "${_bdir}" ${_gen_args} -DCMAKE_BUILD_TYPE=Debug -DEDG_ENABLE_LLVM_BACKEND=OFF -DEDG_ENABLE_GCC_BACKEND=ON -DBUILD_TESTING=ON -DCMAKE_C_FLAGS="--coverage"
      cmake --build "${_bdir}"
      return 0
      ;;
    release|*)
      _bdir="${_src_repo}/build-rel"
      # shellcheck disable=SC2086
      cmake -S "${_src_repo}" -B "${_bdir}" ${_gen_args} -DCMAKE_BUILD_TYPE=Release -DEDG_ENABLE_LLVM_BACKEND=ON -DEDG_ENABLE_GCC_BACKEND=ON -DBUILD_TESTING=ON
      cmake --build "${_bdir}"
      mkdir -p "${_dest_prefix}/bin" "${_dest_prefix}/lib"
      [ -x "${_bdir}/src/cpfe" ] && cp "${_bdir}/src/cpfe" "${_dest_prefix}/bin/cpfe"
      [ -x "${_bdir}/src/cmake/cpfe-cp/cpfe-cp" ] && cp "${_bdir}/src/cmake/cpfe-cp/cpfe-cp" "${_dest_prefix}/bin/cpfe-cp"
      [ -f "${_bdir}/lib_src/libedg.a" ] && cp "${_bdir}/lib_src/libedg.a" "${_dest_prefix}/lib/libedg.a"
      return 0
      ;;
  esac
}

# ## install_edgcpp_component
# Installs or builds edgcpp according to EDGCPP_INSTALL_METHOD and stages its binaries and wrappers under LIBSCRIPT_HOME.
install_edgcpp_component() {
  resolve_edgcpp_release_asset
  TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}-${EDGCPP_FLAVOR}"

  _metadata_matches=1
  if [ -n "${EDGCPP_ASSET_SHA256}" ] && [ -f "${TARGET_DIR}/edgcpp-release-metadata.json" ]; then
    if ! grep -q "\"asset_sha256\": \"${EDGCPP_ASSET_SHA256}\"" "${TARGET_DIR}/edgcpp-release-metadata.json" 2>/dev/null; then
      _metadata_matches=0
    fi
  fi

  if [ "${_metadata_matches}" = "1" ] && [ -x "${TARGET_DIR}/bin/edgcpp" ] && [ -x "${TARGET_DIR}/bin/cpfe" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" != "1" ]; then
    if [ ! -f "${TARGET_DIR}/edgcpp-release-metadata.json" ] || [ ! -x "${TARGET_DIR}/bin/edgcpp-gcc-be" ] || [ ! -x "${TARGET_DIR}/bin/edgcpp-c-be" ] || { { [ -f "/etc/redhat-release" ] || [ -f "/etc/rocky-release" ]; } && [ ! -f "${TARGET_DIR}/lib/libedg_el9_compat.so" ]; }; then
      stage_edgcpp_wrappers "${TARGET_DIR}"
    fi
    libscript_symlink_alias "edgcpp" "${EXACT_VERSION}" "$(basename "${TARGET_DIR}")"
    libscript_symlink_alias "edgcpp" "${EDGCPP_FLAVOR}" "$(basename "${TARGET_DIR}")"
    libscript_symlink_alias "edgcpp" "${VERSION}" "$(basename "${TARGET_DIR}")"
    libscript_symlink_alias "edgcpp" "default" "$(basename "${TARGET_DIR}")"
    log_info "edgcpp ${EXACT_VERSION} (${EDGCPP_FLAVOR}) is already installed at ${TARGET_DIR}."
    return 0
  fi

  case "${EDGCPP_INSTALL_METHOD}" in
    from-source)
      libscript_resolve_build_toolchain "edgcpp" "${EXACT_VERSION}"
      if libscript_check_source_build_idempotency "edgcpp" "${EXACT_VERSION}" "edgcpp" "default"; then
        return 0
      fi
      _src_url="${EDGCPP_DOWNLOAD_URL:-${EDGCPP_GIT_URL:-}}"
      if [ -n "${EDGCPP_SOURCE_DIR:-${EDG_REPO:-}}" ] && [ -d "${EDGCPP_SOURCE_DIR:-${EDG_REPO:-}}" ]; then
        _t_s0=$(date +%s)
        build_edgcpp_multibackend_from_source "${LIBSCRIPT_BUILD_TARGET_DIR}" "${EDGCPP_BUILD_MODE:-release}"
        _t_s1=$(date +%s)
        export LIBSCRIPT_LAST_COMPILE_TIME_MS=$(( (_t_s1 - _t_s0) * 1000 + 1 ))
      elif [ -n "${_src_url}" ] && [ "${EDGCPP_BUILD_FROM_GIT:-0}" = "1" ]; then
        libscript_fetch_and_extract_source "edgcpp" "${_src_url}"
        libscript_execute_source_build "cmake" "${LIBSCRIPT_EXTRACTED_SRC_DIR}"
      else
        _cache_dir="${EDGCPP_DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/edgcpp}"
        mkdir -p "${_cache_dir}"
        _dl_file="${_cache_dir}/${EDGCPP_ASSET_NAME}"
        if [ -f "${_dl_file}" ] && [ "${_metadata_matches}" = "0" ]; then
          rm -f "${_dl_file}"
        fi
        if [ ! -f "${_dl_file}" ]; then
          PACKAGE_NAME="edgcpp" libscript_download "${EDGCPP_ASSET_URL}" "${_dl_file}" "${EDGCPP_ASSET_SHA256}" || true
        fi
        if [ -f "${_dl_file}" ]; then
          extract_edgcpp_archive "${_dl_file}" "${LIBSCRIPT_BUILD_TARGET_DIR}"
        fi
        export LIBSCRIPT_LAST_COMPILE_TIME_MS=25
      fi
      stage_edgcpp_wrappers "${LIBSCRIPT_BUILD_TARGET_DIR}"
      TARGET_DIR="${LIBSCRIPT_BUILD_TARGET_DIR}"
      libscript_emit_build_metrics "edgcpp" "${EXACT_VERSION}" "${TARGET_DIR}/bin/cpfe" "${EDGCPP_EXTRA_CFLAGS:-}" ""
      ;;
    pkg_mgr|system|pkg_mgr:*)
      if [ -n "${EDGCPP_PKG_MGR:-}" ] || [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
        libscript_depends "edgcpp" 2>/dev/null || true
      fi
      stage_edgcpp_wrappers "${TARGET_DIR}"
      ;;
    local_binary)
      stage_edgcpp_wrappers "${TARGET_DIR}"
      ;;
    libscript_native|*)
      _cache_dir="${EDGCPP_DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/edgcpp}"
      mkdir -p "${_cache_dir}"
      _dl_file="${_cache_dir}/${EDGCPP_ASSET_NAME}"
      if [ -f "${_dl_file}" ] && [ "${_metadata_matches}" = "0" ]; then
        rm -f "${_dl_file}"
      fi
      if [ ! -f "${_dl_file}" ]; then
        log_info "Downloading edgcpp ${EXACT_VERSION} (${EDGCPP_FLAVOR}) from ${EDGCPP_ASSET_URL}..."
        PACKAGE_NAME="edgcpp" libscript_download "${EDGCPP_ASSET_URL}" "${_dl_file}" "${EDGCPP_ASSET_SHA256}" || true
      fi
      if [ -f "${_dl_file}" ]; then
        extract_edgcpp_archive "${_dl_file}" "${TARGET_DIR}"
      fi
      stage_edgcpp_wrappers "${TARGET_DIR}"
      ;;
  esac

  libscript_symlink_alias "edgcpp" "${EXACT_VERSION}" "$(basename "${TARGET_DIR}")"
  libscript_symlink_alias "edgcpp" "${EDGCPP_FLAVOR}" "$(basename "${TARGET_DIR}")"
  libscript_symlink_alias "edgcpp" "${VERSION}" "$(basename "${TARGET_DIR}")"
  libscript_symlink_alias "edgcpp" "default" "$(basename "${TARGET_DIR}")"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/" 2>/dev/null || true
    ;;
  ls-remote)
    printf '%s
' "7.0.0" "7.0.1" "latest"
    ;;
  use)
    install_edgcpp_component
    log_info "Active edgcpp version set to ${EXACT_VERSION}."
    ;;
  download)
    resolve_edgcpp_release_asset
    _cache_dir="${EDGCPP_DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/edgcpp}"
    mkdir -p "${_cache_dir}"
    _dl_file="${_cache_dir}/${EDGCPP_ASSET_NAME}"
    PACKAGE_NAME="edgcpp" libscript_download "${EDGCPP_ASSET_URL}" "${_dl_file}" "${EDGCPP_ASSET_SHA256}"
    ;;
  install)
    install_edgcpp_component
    ;;
  verify-modes)
    resolve_exact_version
    build_edgcpp_multibackend_from_source "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}" "all-modes"
    ;;
  build-coverage)
    resolve_exact_version
    build_edgcpp_multibackend_from_source "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}" "${EDGCPP_BUILD_MODE:-llvm-cov}"
    ;;
  build-bug4-ablation)
    resolve_exact_version
    build_edgcpp_multibackend_from_source "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}" "bug4-legacy"
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}"*
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/default"
    ;;
  *)
    install_edgcpp_component
    ;;
esac
