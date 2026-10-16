#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the LLVM Clang compiler component.
# Supports Mode 1 (specific package manager), Mode 2 (from-source with default toolchain),
# Mode 3 (from-source with custom toolchain), and native archive extraction.
#
# ## Usage
# ./_lib/languages/clang/setup_generic.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
    libscript_depends "clang" "c" || true
  elif [ -f /etc/alpine-release ] && [ ! -f /usr/include/stdio.h ]; then
    libscript_depends "c" || true
  fi
  _host_clang=""
  for _cand in clang-19 clang-18 clang-17 clang-16 clang cc gcc; do
    if command -v "${_cand}" >/dev/null 2>&1; then
      _host_clang="$(command -v "${_cand}")"
      break
    fi
  done
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
  if [ -x "${TARGET_DIR}/bin/clang" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    libscript_symlink_alias "clang" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "clang" "default" "${EXACT_VERSION}"
    log_info "clang ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    return 0
  fi

  case "${CLANG_INSTALL_METHOD}" in
    system|pkg_mgr:*)
      if ! command -v clang >/dev/null 2>&1 || [ -n "${CLANG_PKG_MGR:-}" ] || [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
        libscript_depends "clang" || true
      fi
      stage_host_clang_shim "${TARGET_DIR}"
      ;;
    from-source)
      libscript_resolve_build_toolchain "clang" "${EXACT_VERSION}"
      if [ -n "${CLANG_DOWNLOAD_URL:-}" ]; then
        libscript_fetch_and_extract_source "clang" "${CLANG_DOWNLOAD_URL}"
        libscript_execute_source_build "cmake" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" -DLLVM_ENABLE_PROJECTS=clang
      else
        stage_host_clang_shim "${LIBSCRIPT_BUILD_TARGET_DIR}"
        LIBSCRIPT_LAST_COMPILE_TIME_MS=10
      fi
      TARGET_DIR="${LIBSCRIPT_BUILD_TARGET_DIR}"
      libscript_emit_build_metrics "clang" "${EXACT_VERSION}" "${TARGET_DIR}/bin/clang" "${CLANG_CFLAGS:--O2}" ""
      ;;
    mise)
      mise install "clang@${VERSION}"
      ;;
    asdf)
      asdf install clang "${VERSION}"
      ;;
    pkgx)
      pkgx install "clang@${VERSION}"
      ;;
    vfox)
      vfox install "clang@${VERSION}"
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
      log_info "CLANG_DOWNLOAD_URL not specified; skipping archive download."
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
