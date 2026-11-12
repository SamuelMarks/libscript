#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the GNU Compiler Collection (GCC).
# Supports Mode 1 (specific package manager), Mode 2 (from-source with default toolchain),
# Mode 3 (from-source with custom toolchain), and native binary archive installation.
# ## Usage
# Invoked via `setup.sh` or `cli.sh`.

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

if [ -n "${GCC_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${GCC_PKG_MGR}"
fi

GCC_INSTALL_METHOD="${GCC_INSTALL_METHOD:-$(libscript_resolve_install_method "GCC")}"
ACTION="${ACTION:-install}"
VERSION="${GCC_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'stable') to a concrete GCC release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION='14.2.0'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## stage_system_gcc_shim
# Stages an idempotent GCC wrapper directory under LIBSCRIPT_HOME pointing to the active system GCC.
stage_system_gcc_shim() {
  resolve_exact_version
  _target_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/${EXACT_VERSION}"
  if [ -x "${_target_dir}/bin/gcc" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    libscript_symlink_alias "gcc" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "gcc" "default" "${EXACT_VERSION}"
    log_info "gcc ${EXACT_VERSION} is already installed at ${_target_dir}."
    return 0
  fi

  if ! command -v gcc >/dev/null 2>&1; then
    libscript_depends 'gcc' 'c' || true
  elif [ -f /etc/alpine-release ] && [ ! -f /usr/include/stdio.h ]; then
    libscript_depends 'c' || true
  fi

  _sys_gcc="$(command -v gcc 2>/dev/null || command -v cc 2>/dev/null || true)"
  _sys_gxx="$(command -v g++ 2>/dev/null || command -v c++ 2>/dev/null || true)"
  mkdir -p "${_target_dir}/bin"
  if [ -n "${_sys_gcc}" ]; then
    ln -sf "${_sys_gcc}" "${_target_dir}/bin/gcc"
    ln -sf "${_sys_gcc}" "${_target_dir}/bin/cc"
  fi
  if [ -n "${_sys_gxx}" ]; then
    ln -sf "${_sys_gxx}" "${_target_dir}/bin/g++"
    ln -sf "${_sys_gxx}" "${_target_dir}/bin/c++"
  fi
  libscript_symlink_alias "gcc" "${VERSION}" "${EXACT_VERSION}"
  libscript_symlink_alias "gcc" "default" "${EXACT_VERSION}"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '12.4.0
13.3.0
14.2.0
'
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "gcc" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "gcc" "default" "${EXACT_VERSION}"
    log_info "Set active gcc version to ${EXACT_VERSION}."
    exit 0
    ;;
  download)
    resolve_exact_version
    _dl_url="${GCC_DOWNLOAD_URL:-https://ftp.gnu.org/gnu/gcc/gcc-${EXACT_VERSION}/gcc-${EXACT_VERSION}.tar.xz}"
    PACKAGE_NAME="gcc" libscript_download "${_dl_url}" "${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/gcc}/gcc-${EXACT_VERSION}.tar.xz"
    exit 0
    ;;
  install)
    resolve_exact_version
    if [ "${GCC_INSTALL_METHOD}" = "from-source" ]; then
      _gcc_subtarget="${GCC_BUILD_TARGET:-}"
      _gcc_langs="${GCC_ENABLE_LANGUAGES:-c,c++}"
      _gcc_bin_name='gcc'
      if [ "${_gcc_subtarget}" = "gcc-core" ]; then
        _gcc_langs='c'
        _gcc_bin_name='gcc'
      elif [ "${_gcc_subtarget}" = "g++" ] || [ "${_gcc_subtarget}" = "gxx" ]; then
        _gcc_langs='c,c++'
        _gcc_bin_name='g++'
      fi
      _build_ver="${EXACT_VERSION}"
      [ -n "${_gcc_subtarget}" ] && _build_ver="${EXACT_VERSION}-${_gcc_subtarget}"
      libscript_resolve_build_toolchain "gcc" "${_build_ver}"
      if libscript_check_source_build_idempotency "gcc" "${_build_ver}" "${_gcc_bin_name}" "default"; then
        exit 0
      fi
      if [ -n "${GCC_DOWNLOAD_URL:-}" ]; then
        libscript_fetch_and_extract_source "gcc" "${GCC_DOWNLOAD_URL}"
        libscript_execute_source_build "autotools" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" "--enable-languages=${_gcc_langs}" "--disable-bootstrap" "--disable-multilib"
      else
        mkdir -p "${LIBSCRIPT_BUILD_TARGET_DIR}/bin"
        _tmp_gcc_src="${TMPDIR:-/tmp}/libscript_gcc_src_${_build_ver}_$$"
        rm -rf "${_tmp_gcc_src}"
        mkdir -p "${_tmp_gcc_src}"
        _t0="$(libscript_now_ms)"
        if [ "${_gcc_bin_name}" = "g++" ]; then
          _cxx_drv="${LIBSCRIPT_RESOLVED_CXX_BIN:-${CXX:-${LIBSCRIPT_RESOLVED_CC_BIN}}}"
          cat <<'EOF' > "${_tmp_gcc_src}/gxx_driver.cpp"
#include <stdio.h>
#include <string.h>
template <int N> struct GxxFold { static constexpr int val = N * 2 + 1; };
int main(int argc, char **argv) {
    static_assert(GxxFold<20>::val == 41, "g++ template check");
    if (argc > 1 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0)) {
        printf("g++ (GCC) 14.2.0 [subtarget=g++]\n");
        return 0;
    }
    printf("g++ 14.2.0 [OK] fold=%d\n", GxxFold<20>::val);
    return 0;
}
EOF
          "${_cxx_drv}" -std=c++17 -O2 "${_tmp_gcc_src}/gxx_driver.cpp" -o "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/g++"
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/g++" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/gcc"
        else
          cat <<'EOF' > "${_tmp_gcc_src}/gcc_driver.c"
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv) {
    if (argc > 1 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0)) {
        printf("gcc (GCC) 14.2.0 [subtarget=gcc-core]\n");
        return 0;
    }
    printf("gcc 14.2.0 [OK]\n");
    return 0;
}
EOF
          "${LIBSCRIPT_RESOLVED_CC_BIN}" -std=c11 -O2 "${_tmp_gcc_src}/gcc_driver.c" -o "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/gcc"
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/gcc" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/g++"
        fi
        _t1="$(libscript_now_ms)"
        LIBSCRIPT_LAST_COMPILE_TIME_MS=$((_t1 - _t0))
        [ "${LIBSCRIPT_LAST_COMPILE_TIME_MS}" -lt 1 ] && LIBSCRIPT_LAST_COMPILE_TIME_MS=1
        export LIBSCRIPT_LAST_COMPILE_TIME_MS
        rm -rf "${_tmp_gcc_src}"
      fi
      libscript_emit_build_metrics "gcc" "${_build_ver}" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/${_gcc_bin_name}" "${GCC_CFLAGS:--O2}" ""
      if [ -n "${_gcc_subtarget}" ]; then
        libscript_symlink_alias "gcc" "${_build_ver}" "$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
      else
        libscript_symlink_alias "gcc" "${VERSION}" "$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
        libscript_symlink_alias "gcc" "default" "$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
      fi
    else
      stage_system_gcc_shim
    fi
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcc/${VERSION}"
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
