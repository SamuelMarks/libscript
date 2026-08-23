#!/bin/sh
# ## Overview
# Generic setup module for aqua.
# 
# ## Usage
# Execute this script to perform generic initialization steps for aqua.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;; esac
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

AQUA_INSTALL_METHOD="$(libscript_resolve_install_method "AQUA")"
ACTION="${ACTION:-install}"
VERSION="${AQUA_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote aqua 2>/dev/null | tail -n 1)
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
    if [ "$AQUA_INSTALL_METHOD" = "mise" ]; then
      mise ls aqua || true
    elif [ "$AQUA_INSTALL_METHOD" = "asdf" ]; then
      asdf list aqua || true
    elif [ "$AQUA_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$AQUA_INSTALL_METHOD" = "vfox" ]; then
      vfox ls aqua || true
    elif [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$AQUA_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote aqua || true
    elif [ "$AQUA_INSTALL_METHOD" = "asdf" ]; then
      asdf list all aqua || true
    elif [ "$AQUA_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$AQUA_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all aqua || true
    else
      if [ -n "${AQUA_RELEASES_URL:-}" ]; then
        curl -sSL "${AQUA_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/aqua" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$AQUA_INSTALL_METHOD" = "mise" ]; then
      mise use "aqua@${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "asdf" ]; then
      asdf global aqua "${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$AQUA_INSTALL_METHOD" = "vfox" ]; then
      vfox use "aqua@${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "vfox" ]; then
      vfox use "aqua@${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "aqua" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "aqua" "default" "${EXACT_VERSION}"
      
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends "curl"
        EXACT_VERSION=$(curl -sL https://api.github.com/repos/aquaproj/aqua/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "aqua ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "aqua" "default" "${EXACT_VERSION}"
      log_info "Set default aqua version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env aqua \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading aqua ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua"
      if [ -n "${AQUA_DOWNLOAD_URL:-}" ]; then
        libscript_download "${AQUA_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua/aqua-${VERSION}.tar.gz"
      else
        log_warn "AQUA_DOWNLOAD_URL is not defined for aqua ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      libscript_depends "aqua"
    elif [ "$AQUA_INSTALL_METHOD" = "mise" ]; then
      mise install "aqua@${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "asdf" ]; then
      asdf install aqua "${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "aqua@${VERSION}"
    elif [ "$AQUA_INSTALL_METHOD" = "vfox" ]; then
      vfox add aqua || true
      vfox install "aqua@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends "curl"
        EXACT_VERSION=$(curl -sL https://api.github.com/repos/aquaproj/aqua/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        libscript_depends "curl" "tar"
        log_info "Installing aqua ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        arch="$(uname -m)"
        case "${arch}" in
          'x86_64') arch='amd64' ;;
          'aarch64'|'arm64') arch='arm64' ;;
        esac
        curl -sSL "https://github.com/aquaproj/aqua/releases/download/v${EXACT_VERSION}/aqua_${os}_${arch}.tar.gz" | tar -xzf - -C "${TARGET_DIR}/bin" || true
        chmod +x "${TARGET_DIR}/bin/aqua" || true
      else
        log_info "aqua ${VERSION} is already installed."
      fi
      libscript_symlink_alias "aqua" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ] || [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aqua}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $AQUA_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ] || [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aqua}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $AQUA_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ] || [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aqua}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $AQUA_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling aqua $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $AQUA_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
