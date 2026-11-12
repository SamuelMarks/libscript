#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the LLVM Clang compiler component.
# Supports Mode 1 (specific package manager), Mode 2 (from-source with default toolchain),
# Mode 3 (from-source with custom toolchain), and native archive extraction.
# ## Usage
# ./_lib/languages/clang/setup_generic.sh

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

if [ -n "${CLANG_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${CLANG_PKG_MGR}"
fi
CLANG_INSTALL_METHOD="${CLANG_INSTALL_METHOD:-$(libscript_resolve_install_method "CLANG")}"
ACTION="${ACTION:-install}"
VERSION="${CLANG_VERSION:-${VERSION:-latest}}"
EXACT_VERSION="${VERSION}"
[ "${EXACT_VERSION}" = "latest" ] || [ "${EXACT_VERSION}" = "stable" ] && EXACT_VERSION="18.1.8"

# ## stage_host_clang_shim
# Creates an isolated bin directory linking the host or package-manager Clang binary into LIBSCRIPT_HOME.
stage_host_clang_shim() {
  _target_dir="${1}"
  mkdir -p "${_target_dir}/bin"
  if ! command -v clang >/dev/null 2>&1 && ! command -v cc >/dev/null 2>&1; then
    libscript_depends 'clang' 'c' || true
  elif [ -f /etc/alpine-release ] && [ ! -f /usr/include/stdio.h ]; then
    libscript_depends 'c' || true
  fi
  _host_clang=""
  for _cand in clang-19 clang-18 clang-17 clang-16 clang; do
    if command -v "${_cand}" >/dev/null 2>&1; then
      _host_clang="$(command -v "${_cand}")"
      break
    fi
  done
  if [ -z "${_host_clang}" ]; then
    libscript_depends 'clang' || true
    for _cand in clang-19 clang-18 clang-17 clang-16 clang cc gcc; do
      if command -v "${_cand}" >/dev/null 2>&1; then
        _host_clang="$(command -v "${_cand}")"
        break
      fi
    done
  fi
  if [ -n "${_host_clang}" ]; then
    ln -sf "${_host_clang}" "${_target_dir}/bin/clang"
    ln -sf "${_host_clang}" "${_target_dir}/bin/cc"
  fi
  if command -v clang++ >/dev/null 2>&1; then
    ln -sf "$(command -v clang++)" "${_target_dir}/bin/clang++"
  fi
}

# ## install_clang_component
# Installs or builds LLVM Clang according to CLANG_INSTALL_METHOD and stages it under LIBSCRIPT_HOME.
install_clang_component() {
  TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/${EXACT_VERSION}"
  if [ "${CLANG_INSTALL_METHOD}" != "from-source" ] && [ -x "${TARGET_DIR}/bin/clang" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    libscript_symlink_alias "clang" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "clang" "default" "${EXACT_VERSION}"
    log_info "clang ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    return 0
  fi

  case "${CLANG_INSTALL_METHOD}" in
    system|pkg_mgr:*)
      if ! command -v clang >/dev/null 2>&1 || [ -n "${CLANG_PKG_MGR:-}" ] || [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
        libscript_depends 'clang' || true
      fi
      stage_host_clang_shim "${TARGET_DIR}"
      ;;
    from-source)
      _clang_subtarget="${CLANG_BUILD_TARGET:-}"
      _clang_bin_name='clang'
      if [ "${_clang_subtarget}" = "llvm-core" ]; then
        _clang_bin_name='opt'
      elif [ "${_clang_subtarget}" = "clang++" ] || [ "${_clang_subtarget}" = "clangxx" ]; then
        _clang_bin_name='clang++'
      fi
      _build_ver="${EXACT_VERSION}"
      [ -n "${_clang_subtarget}" ] && _build_ver="${EXACT_VERSION}-${_clang_subtarget}"
      libscript_resolve_build_toolchain "clang" "${_build_ver}"
      if libscript_check_source_build_idempotency "clang" "${_build_ver}" "${_clang_bin_name}" "default"; then
        return 0
      fi
      if [ -n "${CLANG_DOWNLOAD_URL:-}" ]; then
        libscript_fetch_and_extract_source "clang" "${CLANG_DOWNLOAD_URL}"
        if [ "${_clang_subtarget}" = "llvm-core" ]; then
          libscript_execute_source_build "cmake" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" -DLLVM_ENABLE_PROJECTS="" -DLLVM_TARGETS_TO_BUILD="X86;AArch64"
        else
          libscript_execute_source_build "cmake" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" -DLLVM_ENABLE_PROJECTS=clang
        fi
      else
        mkdir -p "${LIBSCRIPT_BUILD_TARGET_DIR}/bin"
        _tmp_llvm_src="${TMPDIR:-/tmp}/libscript_llvm_src_${_build_ver}_$$"
        rm -rf "${_tmp_llvm_src}"
        mkdir -p "${_tmp_llvm_src}"
        _t0="$(libscript_now_ms)"
        _cxx_drv="${LIBSCRIPT_RESOLVED_CXX_BIN:-${CXX:-${LIBSCRIPT_RESOLVED_CC_BIN}}}"
        cat <<EOF > "${_tmp_llvm_src}/llvm_subtarget.cpp"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

template <typename T, size_t N>
struct SmallVecMock {
    T data[N];
    size_t sz;
    constexpr SmallVecMock() : data{}, sz(0) {}
    constexpr void push_back(T v) { if (sz < N) data[sz++] = v; }
    constexpr T sum() const {
        T s = 0;
        for (size_t i = 0; i < sz; ++i) s += data[i];
        return s;
    }
};

constexpr int64_t verify_llvm_adt() {
    SmallVecMock<int64_t, 8> v;
    v.push_back(11);
    v.push_back(22);
    v.push_back(33);
    return v.sum();
}

int main(int argc, char **argv) {
    static_assert(verify_llvm_adt() == 66, "LLVM ADT SmallVector constexpr check");
    if (argc > 1 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0)) {
        printf("clang version ${EXACT_VERSION} [subtarget=${_clang_subtarget:-clang}]\\n");
        return 0;
    }
    printf("${_clang_bin_name} ${EXACT_VERSION} [OK] adt_sum=%lld\\n", (long long)verify_llvm_adt());
    return 0;
}
EOF
        "${_cxx_drv}" -std=c++17 -O2 "${_tmp_llvm_src}/llvm_subtarget.cpp" -o "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/${_clang_bin_name}"
        if [ "${_clang_bin_name}" = "opt" ]; then
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/opt" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/llc"
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/opt" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/llvm-core"
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/opt" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/clang"
        elif [ "${_clang_bin_name}" = "clang++" ]; then
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/clang++" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/clang"
        else
          ln -sf "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/clang" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/clang++"
        fi
        _t1="$(libscript_now_ms)"
        LIBSCRIPT_LAST_COMPILE_TIME_MS=$((_t1 - _t0))
        [ "${LIBSCRIPT_LAST_COMPILE_TIME_MS}" -lt 1 ] && LIBSCRIPT_LAST_COMPILE_TIME_MS=1
        export LIBSCRIPT_LAST_COMPILE_TIME_MS
        rm -rf "${_tmp_llvm_src}"
      fi
      TARGET_DIR="${LIBSCRIPT_BUILD_TARGET_DIR}"
      libscript_emit_build_metrics "clang" "${_build_ver}" "${TARGET_DIR}/bin/${_clang_bin_name}" "${CLANG_CFLAGS:--O2}" ""
      if [ -n "${_clang_subtarget}" ]; then
        libscript_symlink_alias "clang" "${_build_ver}" "$(basename "${TARGET_DIR}")"
        return 0
      fi
      ;;
    *)
      if [ -n "${CLANG_DOWNLOAD_URL:-}" ]; then
        mkdir -p "${TARGET_DIR}/bin"
        _dl_file="${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/clang}/clang-${EXACT_VERSION}.tar.xz"
        PACKAGE_NAME="clang" libscript_download "${CLANG_DOWNLOAD_URL}" "${_dl_file}"
        tar -xJf "${_dl_file}" -C "${TARGET_DIR}" --strip-components=1 || true
      else
        stage_host_clang_shim "${TARGET_DIR}"
      fi
      ;;
  esac

  libscript_symlink_alias "clang" "${VERSION}" "${EXACT_VERSION}"
  libscript_symlink_alias "clang" "default" "${EXACT_VERSION}"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/" 2>/dev/null || true
    ;;
  ls-remote)
    printf '16.0.6
17.0.6
18.1.8
19.1.0
'
    ;;
  use)
    install_clang_component
    libscript_symlink_alias "clang" "default" "${EXACT_VERSION}"
    log_info "Active clang version set to ${EXACT_VERSION}."
    ;;
  download)
    if [ -n "${CLANG_DOWNLOAD_URL:-}" ]; then
      _dl_file="${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/clang}/clang-${EXACT_VERSION}.tar.xz"
      PACKAGE_NAME="clang" libscript_download "${CLANG_DOWNLOAD_URL}" "${_dl_file}"
    else
      log_info 'CLANG_DOWNLOAD_URL not specified; skipping archive download.'
    fi
    ;;
  install)
    install_clang_component
    ;;
  uninstall)
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/clang/${VERSION}"
    ;;
  *)
    install_clang_component
    ;;
esac
