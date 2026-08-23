#!/bin/sh
# ## Overview
# Generic setup module for pkgx.
# 
# ## Usage
# Execute this script to perform generic initialization steps for pkgx.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

PKGX_INSTALL_METHOD="$(libscript_resolve_install_method "PKGX")"
ACTION="${ACTION:-install}"
VERSION="${PKGX_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote pkgx 2>/dev/null | tail -n 1)
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
    if [ "$PKGX_INSTALL_METHOD" = "mise" ]; then
      mise ls pkgx || true
    elif [ "$PKGX_INSTALL_METHOD" = "asdf" ]; then
      asdf list pkgx || true
    elif [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/pkgx/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$PKGX_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote pkgx || true
    elif [ "$PKGX_INSTALL_METHOD" = "asdf" ]; then
      asdf list all pkgx || true
    else
      if [ -n "${PKGX_RELEASES_URL:-}" ]; then
        curl -sSL "${PKGX_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/pkgx" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$PKGX_INSTALL_METHOD" = "mise" ]; then
      mise use "pkgx@${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "asdf" ]; then
      asdf global pkgx "${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "vfox" ]; then
      vfox use "pkgx@${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "pkgx" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/pkgx/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "pkgx ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "pkgx" "default" "${EXACT_VERSION}"
      log_info "Set default pkgx version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env pkgx \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$PKGX_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading pkgx ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/pkgx..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/pkgx"
      if [ -n "${PKGX_DOWNLOAD_URL:-}" ]; then
        libscript_download "${PKGX_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/pkgx/pkgx-${VERSION}.tar.gz"
      else
        log_warn "PKGX_DOWNLOAD_URL is not defined for pkgx ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      libscript_depends "pkgx"
    elif [ "$PKGX_INSTALL_METHOD" = "mise" ]; then
      mise install "pkgx@${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "asdf" ]; then
      asdf install pkgx "${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "pkgx@${VERSION}"
    elif [ "$PKGX_INSTALL_METHOD" = "vfox" ]; then
      vfox add pkgx || true
      vfox install "pkgx@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
         libscript_depends "curl"
         EXACT_VERSION=$(curl -sL https://api.github.com/repos/pkgxdev/pkgx/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/pkgx/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing pkgx ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        ARCH=$(uname -m)
        OS=$(uname -s | tr "[:upper:]" "[:lower:]")
        if [ "$ARCH" = "x86_64" ]; then ARCH="x86-64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
        if [ "$OS" = "darwin" ]; then OS="darwin"; elif [ "$OS" = "linux" ]; then OS="linux"; fi
        URL="https://github.com/pkgxdev/pkgx/releases/download/v${EXACT_VERSION}/pkgx-${EXACT_VERSION}+${OS}+${ARCH}.tar.xz"
        TEMP_FILE=$(mktemp)
        libscript_depends "curl"
        libscript_depends "tar"
        libscript_depends "xz"
        curl -sSL "$URL" -o "$TEMP_FILE"
        tar -xf "$TEMP_FILE" -C "${TARGET_DIR}/bin" "pkgx" || cp "$TEMP_FILE" "${TARGET_DIR}/bin/pkgx"
        chmod +x "${TARGET_DIR}/bin/pkgx"
        rm -f "$TEMP_FILE"
      else
        log_info "pkgx ${VERSION} is already installed."
      fi
      libscript_symlink_alias "pkgx" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$PKGX_INSTALL_METHOD" = "libscript_native" ] || [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-pkgx}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $PKGX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$PKGX_INSTALL_METHOD" = "libscript_native" ] || [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-pkgx}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $PKGX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$PKGX_INSTALL_METHOD" = "libscript_native" ] || [ "$PKGX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-pkgx}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $PKGX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$PKGX_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling pkgx $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/pkgx/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/pkgx/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $PKGX_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
