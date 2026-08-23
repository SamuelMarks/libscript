#!/bin/sh
# ## Overview
# Generic setup module for cargo-binstall.
# 
# ## Usage
# Execute this script to perform generic initialization steps for cargo-binstall.

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

CARGO_BINSTALL_INSTALL_METHOD="$(libscript_resolve_install_method "CARGO_BINSTALL")"
ACTION="${ACTION:-install}"
VERSION="${CARGO_BINSTALL_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote cargo-binstall 2>/dev/null | tail -n 1)
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
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "mise" ]; then
      mise ls cargo-binstall || true
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "asdf" ]; then
      asdf list cargo-binstall || true
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "vfox" ]; then
      vfox ls cargo_binstall || true
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote cargo-binstall || true
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "asdf" ]; then
      asdf list all cargo-binstall || true
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all cargo_binstall || true
    else
      if [ -n "${CARGO_BINSTALL_RELEASES_URL:-}" ]; then
        curl -sSL "${CARGO_BINSTALL_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/cargo-binstall" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "mise" ]; then
      mise use "cargo-binstall@${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "asdf" ]; then
      asdf global cargo-binstall "${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "vfox" ]; then
      vfox use "cargo_binstall@${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "vfox" ]; then
      vfox use "cargo-binstall@${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "cargo-binstall" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "cargo-binstall" "default" "${EXACT_VERSION}"
      
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends "curl"
        EXACT_VERSION=$(curl -sL https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "cargo-binstall ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "cargo-binstall" "default" "${EXACT_VERSION}"
      log_info "Set default cargo-binstall version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env cargo-binstall \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading cargo-binstall ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall"
      if [ -n "${CARGO_BINSTALL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CARGO_BINSTALL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall/cargo-binstall-${VERSION}.tar.gz"
      else
        log_warn "CARGO_BINSTALL_DOWNLOAD_URL is not defined for cargo-binstall ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      libscript_depends "cargo-binstall"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "mise" ]; then
      mise install "cargo-binstall@${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "asdf" ]; then
      asdf install cargo-binstall "${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "cargo-binstall@${VERSION}"
    elif [ "$CARGO_BINSTALL_INSTALL_METHOD" = "vfox" ]; then
      vfox add cargo-binstall || true
      vfox install "cargo-binstall@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends "curl"
        EXACT_VERSION=$(curl -sL https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing cargo-binstall ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends "curl" "tar"
        mkdir -p "${TARGET_DIR}/bin"
        _os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        arch="$(uname -m)"
        if [ -f /etc/alpine-release ]; then
          arch_musl="${arch}-unknown-linux-musl"
        else
          arch_musl="${arch}-unknown-linux-gnu"
        fi
        if [ "${EXACT_VERSION}" = "latest" ]; then
          EXACT_VERSION=$(curl -sL https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
        fi
        curl -sSL "https://github.com/cargo-bins/cargo-binstall/releases/download/v${EXACT_VERSION}/cargo-binstall-${arch_musl}.tgz" | tar -xzf - -C "${TARGET_DIR}/bin" || true
        chmod +x "${TARGET_DIR}/bin/cargo-binstall" || true
      else
        log_info "cargo-binstall ${VERSION} is already installed."
      fi
      libscript_symlink_alias "cargo-binstall" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ] || [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cargo-binstall}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $CARGO_BINSTALL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ] || [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cargo-binstall}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $CARGO_BINSTALL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ] || [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cargo-binstall}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $CARGO_BINSTALL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling cargo-binstall $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $CARGO_BINSTALL_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
