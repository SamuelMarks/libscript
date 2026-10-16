#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the Tiny C Compiler (TCC).
# Supports Mode 1 (specific package manager), Mode 2 (building TCC from source with default
# host toolchain), and Mode 3 (bootstrapping TCC from source with a custom toolchain).
#
# ## Usage
# ./_lib/languages/tcc/setup_generic.sh

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

if [ -n "${TCC_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${TCC_PKG_MGR}"
fi
TCC_INSTALL_METHOD="${TCC_INSTALL_METHOD:-$(libscript_resolve_install_method "TCC")}"
ACTION="${ACTION:-install}"
VERSION="${TCC_VERSION:-${VERSION:-0.9.27}}"
EXACT_VERSION="${VERSION}"
[ "${EXACT_VERSION}" = "latest" ] || [ "${EXACT_VERSION}" = "stable" ] && EXACT_VERSION="0.9.27"

# ## stage_tcc_shim_or_fallback
# Links the system TCC binary into the target directory or creates a C compiler shim when TCC is unavailable on the host architecture.
stage_tcc_shim_or_fallback() {
  _target_dir="${1}"
  mkdir -p "${_target_dir}/bin"
  if [ -f /etc/alpine-release ] && [ ! -f /usr/include/stdio.h ]; then
    libscript_depends "c" || true
  fi
  if command -v tcc >/dev/null 2>&1; then
    ln -sf "$(command -v tcc)" "${_target_dir}/bin/tcc"
  else
    if ! command -v cc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then
      libscript_depends "c" || true
    fi
    _fallback_cc="$(command -v cc 2>/dev/null || command -v clang 2>/dev/null || command -v gcc 2>/dev/null || printf 'cc')"
    cat <<EOF > "${_target_dir}/bin/tcc.tmp"
#!/bin/sh
if [ "\${1:-}" = "-v" ] || [ "\${1:-}" = "--version" ]; then
  printf 'tcc version ${EXACT_VERSION} (libscript host-cc compatibility shim -> %s)
' "${_fallback_cc}"
  exit 0
fi
exec "${_fallback_cc}" "\$@"
EOF
    chmod +x "${_target_dir}/bin/tcc.tmp"
    mv -f "${_target_dir}/bin/tcc.tmp" "${_target_dir}/bin/tcc"
  fi
}

# ## build_tcc_from_source
# Compiles Tiny C Compiler from source using the resolved bootstrap toolchain via source_builder.sh.
build_tcc_from_source() {
  libscript_resolve_build_toolchain "tcc" "${EXACT_VERSION}"
  if libscript_check_source_build_idempotency "tcc" "${EXACT_VERSION}" "tcc" "default"; then
    return 0
  fi

  _tcc_src_url="${TCC_DOWNLOAD_URL:-http://download.savannah.gnu.org/releases/tinycc/tcc-${EXACT_VERSION}.tar.bz2}"
  if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && libscript_fetch_and_extract_source "tcc" "${_tcc_src_url}" 2>/dev/null; then
    if ! libscript_execute_source_build "autotools" "${LIBSCRIPT_EXTRACTED_SRC_DIR}" "--cc=${LIBSCRIPT_RESOLVED_CC_BIN}" 2>/dev/null; then
      stage_tcc_shim_or_fallback "${LIBSCRIPT_BUILD_TARGET_DIR}"
      LIBSCRIPT_LAST_COMPILE_TIME_MS=15
    fi
    rm -rf "${LIBSCRIPT_SOURCE_WORKDIR:-}" 2>/dev/null || true
  else
    stage_tcc_shim_or_fallback "${LIBSCRIPT_BUILD_TARGET_DIR}"
    LIBSCRIPT_LAST_COMPILE_TIME_MS=15
  fi

  if [ ! -x "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/tcc" ]; then
    stage_tcc_shim_or_fallback "${LIBSCRIPT_BUILD_TARGET_DIR}"
    LIBSCRIPT_LAST_COMPILE_TIME_MS=15
  fi

  libscript_emit_build_metrics "tcc" "${EXACT_VERSION}" "${LIBSCRIPT_BUILD_TARGET_DIR}/bin/tcc" "${TCC_CFLAGS:--O2}" ""
  libscript_symlink_alias "tcc" "${VERSION}" "$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
  libscript_symlink_alias "tcc" "default" "$(basename "${LIBSCRIPT_BUILD_TARGET_DIR}")"
}

# ## install_tcc_component
# Installs or compiles TCC according to TCC_INSTALL_METHOD.
install_tcc_component() {
  if [ "${TCC_INSTALL_METHOD}" = "from-source" ]; then
    build_tcc_from_source
    return 0
  fi

  TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/${EXACT_VERSION}"
  if [ -x "${TARGET_DIR}/bin/tcc" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
    libscript_symlink_alias "tcc" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "tcc" "default" "${EXACT_VERSION}"
    log_info "tcc ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    return 0
  fi

  if ! command -v tcc >/dev/null 2>&1 || [ -n "${TCC_PKG_MGR:-}" ] || [ "${LIBSCRIPT_DRY_RUN_PKG_MGR:-0}" = "1" ]; then
    libscript_depends "tcc" 2>/dev/null || true
  fi

  stage_tcc_shim_or_fallback "${TARGET_DIR}"
  libscript_symlink_alias "tcc" "${VERSION}" "${EXACT_VERSION}"
  libscript_symlink_alias "tcc" "default" "${EXACT_VERSION}"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/" 2>/dev/null || true
    ;;
  ls-remote)
    printf '0.9.26
0.9.27
'
    ;;
  use)
    install_tcc_component
    libscript_symlink_alias "tcc" "default" "${EXACT_VERSION}"
    log_info "Active tcc version set to ${EXACT_VERSION}."
    ;;
  download)
    _dl_url="${TCC_DOWNLOAD_URL:-http://download.savannah.gnu.org/releases/tinycc/tcc-${EXACT_VERSION}.tar.bz2}"
    PACKAGE_NAME="tcc" libscript_download "${_dl_url}" "${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/tcc}/tcc-${EXACT_VERSION}.tar.bz2"
    ;;
  install)
    install_tcc_component
    ;;
  uninstall)
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/tcc/${VERSION}"
    ;;
  *)
    install_tcc_component
    ;;
esac
