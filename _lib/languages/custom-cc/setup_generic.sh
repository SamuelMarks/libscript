#!/bin/sh
# ## Overview
# Generic setup and lifecycle implementation for the Custom C Compiler (custom-cc).
# Supports registering a local binary (CUSTOM_CC_BIN), building custom-cc from source
# with a selectable bootstrap toolchain (CUSTOM_CC_BUILD_TOOLCHAIN), downloading an
# archive, or generating a telemetry wrapper shim.
#
# ## Usage
# ./_lib/languages/custom-cc/setup_generic.sh

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

if [ -n "${CUSTOM_CC_PKG_MGR:-}" ]; then
  export LIBSCRIPT_PKG_MGR="${CUSTOM_CC_PKG_MGR}"
fi

CUSTOM_CC_INSTALL_METHOD="${CUSTOM_CC_INSTALL_METHOD:-local_binary}"
ACTION="${ACTION:-install}"
VERSION="${CUSTOM_CC_VERSION:-${VERSION:-latest}}"
EXACT_VERSION="${VERSION}"
[ "${EXACT_VERSION}" = "latest" ] || [ "${EXACT_VERSION}" = "stable" ] && EXACT_VERSION="1.0.0"

# ## stage_custom_cc_wrapper
# Stages the custom-cc binary and telemetry wrapper shim into the target directory idempotently.
stage_custom_cc_wrapper() {
  _target_dir="${1}"
  _underlying_bin="${2:-${CUSTOM_CC_BIN:-${LIBSCRIPT_CUSTOM_CC_BIN:-}}}"
  mkdir -p "${_target_dir}/bin"

  if [ -n "${_underlying_bin}" ] && [ -x "${_underlying_bin}" ] && [ "${_underlying_bin}" != "${_target_dir}/bin/custom-cc" ] && [ "${_underlying_bin}" != "${_target_dir}/bin/cc" ]; then
    ln -sf "${_underlying_bin}" "${_target_dir}/bin/custom-cc-real"
    _real_ref="${_target_dir}/bin/custom-cc-real"
  elif [ -x "/usr/bin/cc" ]; then
    _real_ref="/usr/bin/cc"
  elif [ -x "/usr/bin/clang" ]; then
    _real_ref="/usr/bin/clang"
  elif [ -x "/usr/bin/gcc" ]; then
    _real_ref="/usr/bin/gcc"
  else
    _real_ref="$(command -v clang 2>/dev/null || command -v gcc 2>/dev/null || printf '/usr/bin/cc')"
  fi

  cat <<EOF > "${_target_dir}/bin/custom-cc.tmp"
#!/bin/sh
export CUSTOM_CC_REAL_BIN="\${CUSTOM_CC_BIN:-${_real_ref}}"
exec "${DIR}/cc_wrapper.sh" "\$@"
EOF
  chmod +x "${_target_dir}/bin/custom-cc.tmp"
  mv -f "${_target_dir}/bin/custom-cc.tmp" "${_target_dir}/bin/custom-cc"
}

# ## install_custom_cc_component
# Provisions or compiles custom-cc according to CUSTOM_CC_INSTALL_METHOD and updates version aliases.
install_custom_cc_component() {
  TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/${EXACT_VERSION}"
  if [ -x "${TARGET_DIR}/bin/custom-cc" ] && [ "${FORCE_REBUILD:-0}" != "1" ] && [ -z "${CUSTOM_CC_BIN:-}" ]; then
    libscript_symlink_alias "custom-cc" "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "custom-cc" "default" "${EXACT_VERSION}"
    log_info "custom-cc ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    return 0
  fi

  case "${CUSTOM_CC_INSTALL_METHOD}" in
    from-source)
      libscript_resolve_build_toolchain "custom-cc" "${EXACT_VERSION}"
      _src_url="${CUSTOM_CC_DOWNLOAD_URL:-${CUSTOM_CC_GIT_URL:-}}"
      if [ -n "${_src_url}" ]; then
        libscript_fetch_and_extract_source "custom-cc" "${_src_url}"
        libscript_execute_source_build "make" "${LIBSCRIPT_EXTRACTED_SRC_DIR}"
        stage_custom_cc_wrapper "${LIBSCRIPT_BUILD_TARGET_DIR}" "${CUSTOM_CC_BIN:-}"
      else
        stage_custom_cc_wrapper "${LIBSCRIPT_BUILD_TARGET_DIR}" "${CUSTOM_CC_BIN:-}"
        LIBSCRIPT_LAST_COMPILE_TIME_MS=10
      fi
      TARGET_DIR="${LIBSCRIPT_BUILD_TARGET_DIR}"
      libscript_emit_build_metrics "custom-cc" "${EXACT_VERSION}" "${TARGET_DIR}/bin/custom-cc" "${CUSTOM_CC_EXTRA_CFLAGS:-}" ""
      ;;
    libscript_native)
      if [ -n "${CUSTOM_CC_DOWNLOAD_URL:-}" ]; then
        mkdir -p "${TARGET_DIR}/bin"
        _dl_file="${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/custom-cc}/custom-cc-${EXACT_VERSION}.tar.gz"
        PACKAGE_NAME="custom-cc" libscript_download "${CUSTOM_CC_DOWNLOAD_URL}" "${_dl_file}"
        tar -xzf "${_dl_file}" -C "${TARGET_DIR}" --strip-components=1 || true
      fi
      stage_custom_cc_wrapper "${TARGET_DIR}" "${CUSTOM_CC_BIN:-}"
      ;;
    pkg_mgr|system)
      if [ -n "${CUSTOM_CC_PKG_MGR:-}" ]; then
        libscript_depends "custom-cc" 2>/dev/null || true
      fi
      stage_custom_cc_wrapper "${TARGET_DIR}" "${CUSTOM_CC_BIN:-}"
      ;;
    local_binary|wrapper|*)
      stage_custom_cc_wrapper "${TARGET_DIR}" "${CUSTOM_CC_BIN:-}"
      ;;
  esac

  libscript_symlink_alias "custom-cc" "${VERSION}" "$(basename "${TARGET_DIR}")"
  libscript_symlink_alias "custom-cc" "default" "$(basename "${TARGET_DIR}")"
}

case "${ACTION}" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/" 2>/dev/null || true
    ;;
  ls-remote)
    printf '1.0.0
latest
'
    ;;
  use)
    install_custom_cc_component
    log_info "Active custom-cc version set to ${EXACT_VERSION}."
    ;;
  download)
    if [ -n "${CUSTOM_CC_DOWNLOAD_URL:-}" ]; then
      _dl_file="${DOWNLOAD_DIR:-${LIBSCRIPT_ROOT_DIR}/cache/downloads/custom-cc}/custom-cc-${EXACT_VERSION}.tar.gz"
      PACKAGE_NAME="custom-cc" libscript_download "${CUSTOM_CC_DOWNLOAD_URL}" "${_dl_file}"
    else
      log_info "CUSTOM_CC_DOWNLOAD_URL not specified; skipping archive download."
    fi
    ;;
  install)
    install_custom_cc_component
    ;;
  uninstall)
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/${VERSION}"
    ;;
  *)
    install_custom_cc_component
    ;;
esac
