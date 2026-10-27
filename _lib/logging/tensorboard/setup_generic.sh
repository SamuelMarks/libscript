#!/bin/sh
# ## Overview
# Generic setup module for tensorboard.
# 
# ## Usage
# Execute this script to perform generic initialization steps for tensorboard.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

TENSORBOARD_INSTALL_METHOD="$(libscript_resolve_install_method "TENSORBOARD")"
ACTION="${ACTION:-install}"
VERSION="${TENSORBOARD_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote tensorboard 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "tensorboard" "$ACTION" "$VERSION" "${TENSORBOARD_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${TENSORBOARD_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${TENSORBOARD_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/tensorflow/tensorboard" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "tensorboard" "$ACTION" "$VERSION" "${TENSORBOARD_INSTALL_METHOD}"
    ;;
  download)
    if [ "$TENSORBOARD_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading tensorboard ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tensorboard..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tensorboard"
      if [ -n "${TENSORBOARD_DOWNLOAD_URL:-}" ]; then
        libscript_download "${TENSORBOARD_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tensorboard/tensorboard-${VERSION}.tar.gz"
      else
        log_warn "TENSORBOARD_DOWNLOAD_URL is not defined for tensorboard ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$TENSORBOARD_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "tensorboard" 2>/dev/null; then
        log_warn 'System package for tensorboard failed. Falling back to native venv python3 installation.'
        TENSORBOARD_INSTALL_METHOD='libscript_native'
      fi
    fi

    # libscript_native implementation
    resolve_exact_version
    libscript_depends 'python'
    
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/tensorboard/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing tensorboard ${VERSION} to ${TARGET_DIR}..."
      if ! type libscript_python_venv >/dev/null 2>&1; then
        _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        unset SCRIPT_NAME || true
        [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
        [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
      fi
      libscript_python_venv "${TARGET_DIR}"
      
      if [ "$EXACT_VERSION" = "latest" ]; then
        "${TARGET_DIR}/bin/pip" install --upgrade tensorboard || PIP_FAILED=1
      else
        "${TARGET_DIR}/bin/pip" install "tensorboard==${EXACT_VERSION}" || PIP_FAILED=1
      fi
      
      if [ "${PIP_FAILED:-0}" = "1" ]; then
        log_error 'Failed to install tensorboard via pip.'
        exit 1
      fi
    else
      log_info "tensorboard ${VERSION} is already installed."
    fi
    
    libscript_symlink_alias "tensorboard" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "tensorboard" "$ACTION" "$VERSION" "${TENSORBOARD_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
