#!/bin/sh
# ## Overview
# Generic setup module for rustup.
# 
# ## Usage
# Execute this script to perform generic initialization steps for rustup.

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

RUSTUP_INSTALL_METHOD="$(libscript_resolve_install_method "RUSTUP")"
ACTION="${ACTION:-install}"
VERSION="${RUSTUP_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote rustup 2>/dev/null | tail -n 1)
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
    if [ "$RUSTUP_INSTALL_METHOD" = "mise" ]; then
      mise ls rustup || true
    elif [ "$RUSTUP_INSTALL_METHOD" = "asdf" ]; then
      asdf list rustup || true
    elif [ "$RUSTUP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$RUSTUP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls rustup || true
    elif [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$RUSTUP_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote rustup || true
    elif [ "$RUSTUP_INSTALL_METHOD" = "asdf" ]; then
      asdf list all rustup || true
    elif [ "$RUSTUP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$RUSTUP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all rustup || true
    else
      if [ -n "${RUSTUP_RELEASES_URL:-}" ]; then
        curl -sSL "${RUSTUP_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/rustup" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$RUSTUP_INSTALL_METHOD" = "mise" ]; then
      mise use "rustup@${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "asdf" ]; then
      asdf global rustup "${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$RUSTUP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "rustup@${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "rustup@${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "rustup" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "rustup ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "rustup" "default" "${EXACT_VERSION}"
      log_info "Set default rustup version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env rustup \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading rustup ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup"
      if [ -n "${RUSTUP_DOWNLOAD_URL:-}" ]; then
        libscript_download "${RUSTUP_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup/rustup-${VERSION}.tar.gz"
      else
        log_warn "RUSTUP_DOWNLOAD_URL is not defined for rustup ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      libscript_depends "rustup"
    elif [ "$RUSTUP_INSTALL_METHOD" = "mise" ]; then
      mise install "rustup@${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "asdf" ]; then
      asdf install rustup "${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "rustup@${VERSION}"
    elif [ "$RUSTUP_INSTALL_METHOD" = "vfox" ]; then
      vfox add rustup || true
      vfox install "rustup@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing rustup ${VERSION} natively to ${TARGET_DIR}..."
        if [ "$UNAME_LOWER" = "freebsd" ]; then
          log_info "No native binary for FreeBSD. Falling back to system package manager for rustup..."
          libscript_depends "rust"
          mkdir -p "${TARGET_DIR}/.cargo/bin"
          ln -sf "$(command -v "rustc")" "${TARGET_DIR}/.cargo/bin/rustc" || true
          ln -sf "$(command -v "cargo")" "${TARGET_DIR}/.cargo/bin/cargo" || true
        else
          libscript_depends "curl"
          mkdir -p "${TARGET_DIR}"
          export RUSTUP_HOME="${TARGET_DIR}/.rustup"
          export CARGO_HOME="${TARGET_DIR}/.cargo"
          unset RUSTUP_VERSION

          curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        fi
      else
        log_info "rustup ${VERSION} is already installed."
      fi
      libscript_symlink_alias "rustup" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ] || [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-rustup}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $RUSTUP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ] || [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-rustup}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $RUSTUP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ] || [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-rustup}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $RUSTUP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling rustup $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $RUSTUP_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
