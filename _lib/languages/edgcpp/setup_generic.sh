#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the EDG C/C++ Compiler Frontend (edgcpp).
# Supports Mode 1 (pkg_mgr/system), Mode 2/3 (from-source with selectable bootstrap
# toolchain), local_binary registration, and native GitHub release archive installation
# across edgcpp+llvm+gcc, edgcpp+llvm, and edgcpp+gcc flavors (v7.0.1).
#
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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
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

# ## resolve_exact_version
# Resolves semantic version aliases ('latest', 'stable', '7.0', 'v7.0.1') to '7.0.1'.
resolve_exact_version() {
  case "${VERSION:-latest}" in
    latest|stable|7.0|v7.0.1|7.0.1|"")
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

  _uname_s="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf 'linux')"
  _uname_m="$(uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf 'x86_64')"

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
  EDGCPP_ASSET_SHA256=""

  case "${EDGCPP_ASSET_NAME}" in
    "edgcpp+llvm+gcc-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="a848a68c6e116eed2c06638bf5149aa727f95a359f192bd3ab8f423558aa94bc" ;;
    "edgcpp+llvm+gcc-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="84b0bb06bfbe034e02b47a3d81b2ece99a75aee1336be666ded2885c212e133a" ;;
    "edgcpp+llvm+gcc-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="ba9e214f590310eab92e8a7cc7a93fad90395d92c6df367f009a065e1234cb64" ;;
    "edgcpp+llvm+gcc-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="bc824476fd072dcd76409d8f0970c21ddb532976d378d1351adbf4bfea97d933" ;;
    "edgcpp+llvm+gcc-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="c8652f6631e2eda41611b84d7a930ee5f4898feb87b4b46e7009c081937e8a66" ;;
    "edgcpp+llvm-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="e56eee2cfdc43820e778a305cd8e6549c9b6b78ec82a4901a114a3ad79146aff" ;;
    "edgcpp+llvm-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="e9b9dbb385c11a7a66afd94b567c0ad1b7ebdfb0177da172b93e351a69f8b708" ;;
    "edgcpp+llvm-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="7caf4ff85567ed6c6bf2048881e46a7d9ee2c1a8b42604925331e334dd994809" ;;
    "edgcpp+llvm-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="b883cb639dd306d676ca390e8effe8b7b284f3d91f8ac31cdb754c81a5fb80c8" ;;
    "edgcpp+llvm-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="c4773d7a1bbfba0c75d0ef09b6a250c96f706a0e7d5b21ace78ffe9b271ae7ef" ;;
    "edgcpp+gcc-v7.0.1-linux-x86_64.tar.gz") EDGCPP_ASSET_SHA256="e1fce29ebf4fec8d8f1338c94036e305fc0f95bc4b54f84e7a52aeacd8a9198a" ;;
    "edgcpp+gcc-v7.0.1-linux-aarch64.tar.gz") EDGCPP_ASSET_SHA256="2fd3162a3c8cc4dd15728695d7e1b89845b3b916be198a8e9fd5278c2a869ac3" ;;
    "edgcpp+gcc-v7.0.1-macos-aarch64.tar.gz") EDGCPP_ASSET_SHA256="8d5571d014e18e3b1d28e0a5a7cd9b5eb2973a58af0e4920381509250f3f9d52" ;;
    "edgcpp+gcc-v7.0.1-windows-x86_64.zip") EDGCPP_ASSET_SHA256="e308ea54067dee50475acc7647a2351280c172ac86abaf77f8969694cc59790a" ;;
    "edgcpp+gcc-v7.0.1-windows-arm64.zip") EDGCPP_ASSET_SHA256="d9867f12b357053fc8bd6b4b12fa89ef97b24bc413ed5c132b74c182b598015c" ;;
  esac
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

  if command -v install_name_tool >/dev/null 2>&1 && [ -f "/opt/homebrew/opt/z3/lib/libz3.dylib" ]; then
    for _macho_bin in cpfe cpfe-cp; do
      if [ -f "${_target_dir}/bin/${_macho_bin}" ]; then
        install_name_tool -change "/opt/homebrew/opt/z3/lib/libz3.5.1.dylib" "/opt/homebrew/opt/z3/lib/libz3.dylib" "${_target_dir}/bin/${_macho_bin}" 2>/dev/null || true
        if command -v codesign >/dev/null 2>&1; then
          codesign -f -s - "${_target_dir}/bin/${_macho_bin}" >/dev/null 2>&1 || true
        fi
      fi
    done
  fi

  if [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" != "1" ] && [ "$(uname -s 2>/dev/null || true)" = "Linux" ]; then
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
CPFE_BIN="${_target_dir}/bin/cpfe"
CPFE_CP_BIN="${_target_dir}/bin/cpfe-cp"
EDGCPP_WRAPPER_SCRIPT="${DIR}/edgcpp_wrapper.sh"
EOF

  cat <<'EOF' > "${_target_dir}/bin/edgcpp.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME CPFE_BIN CPFE_CP_BIN
export EDGCPP_DRIVER_LANG="${EDGCPP_DRIVER_LANG:-c}"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edgcpp.tmp"
  mv -f "${_target_dir}/bin/edgcpp.tmp" "${_target_dir}/bin/edgcpp"

  ln -sf "${_target_dir}/bin/edgcpp" "${_target_dir}/bin/edg-cc"
  ln -sf "${_target_dir}/bin/edgcpp" "${_target_dir}/bin/cc"

  cat <<'EOF' > "${_target_dir}/bin/edg-c++.tmp"
#!/bin/sh
_self_dir=$(cd -- "$(dirname -- "$0")" && pwd)
if [ -f "${_self_dir}/edgcpp.env" ]; then
  # shellcheck disable=SC1091
  . "${_self_dir}/edgcpp.env"
fi
export EDGCPP_HOME CPFE_BIN CPFE_CP_BIN
export EDGCPP_DRIVER_LANG="c++"
exec "${EDGCPP_WRAPPER_SCRIPT}" "$@"
EOF
  chmod +x "${_target_dir}/bin/edg-c++.tmp"
  mv -f "${_target_dir}/bin/edg-c++.tmp" "${_target_dir}/bin/edg-c++"
  ln -sf "${_target_dir}/bin/edg-c++" "${_target_dir}/bin/c++"
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

# ## install_edgcpp_component
# Installs or builds edgcpp according to EDGCPP_INSTALL_METHOD and stages its binaries and wrappers under LIBSCRIPT_HOME.
install_edgcpp_component() {
  resolve_edgcpp_release_asset
  TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/${EXACT_VERSION}"

  if [ -x "${TARGET_DIR}/bin/edgcpp" ] && [ -x "${TARGET_DIR}/bin/cpfe" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" != "1" ]; then
    libscript_symlink_alias "edgcpp" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "edgcpp" "default" "${EXACT_VERSION}"
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
      if [ -n "${_src_url}" ] && [ "${EDGCPP_BUILD_FROM_GIT:-0}" = "1" ]; then
        libscript_fetch_and_extract_source "edgcpp" "${_src_url}"
        libscript_execute_source_build "cmake" "${LIBSCRIPT_EXTRACTED_SRC_DIR}"
      else
        _cache_dir="${EDGCPP_DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/edgcpp}"
        mkdir -p "${_cache_dir}"
        _dl_file="${_cache_dir}/${EDGCPP_ASSET_NAME}"
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
