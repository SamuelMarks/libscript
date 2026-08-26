#!/bin/sh
# ## Overview
# Generic setup module for brew.
# 
# ## Usage
# Execute this script to perform generic initialization steps for brew.

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

BREW_INSTALL_METHOD="$(libscript_resolve_install_method "BREW")"
ACTION="${ACTION:-install}"
VERSION="${BREW_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote brew 2>/dev/null | tail -n 1)
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
    if [ "$BREW_INSTALL_METHOD" = "mise" ]; then
      mise ls brew || true
    elif [ "$BREW_INSTALL_METHOD" = "asdf" ]; then
      asdf list brew || true
    elif [ "$BREW_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$BREW_INSTALL_METHOD" = "vfox" ]; then
      vfox ls brew || true
    elif [ "$BREW_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/brew/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$BREW_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote brew || true
    elif [ "$BREW_INSTALL_METHOD" = "asdf" ]; then
      asdf list all brew || true
    elif [ "$BREW_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$BREW_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all brew || true
    else
      if [ -n "${BREW_RELEASES_URL:-}" ]; then
        curl -sSL "${BREW_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/brew" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$BREW_INSTALL_METHOD" = "mise" ]; then
      mise use "brew@${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "asdf" ]; then
      asdf global brew "${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$BREW_INSTALL_METHOD" = "vfox" ]; then
      vfox use "brew@${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "vfox" ]; then
      vfox use "brew@${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "brew" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "brew" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/brew/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "brew ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "brew" "default" "${EXACT_VERSION}"
      log_info "Set default brew version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env brew \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$BREW_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading brew ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/brew..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/brew"
      if [ -n "${BREW_DOWNLOAD_URL:-}" ]; then
        libscript_download "${BREW_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/brew/brew-${VERSION}.tar.gz"
      else
        log_warn "BREW_DOWNLOAD_URL is not defined for brew ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$BREW_INSTALL_METHOD" = "system" ]; then
      libscript_depends "brew"
    elif [ "$BREW_INSTALL_METHOD" = "mise" ]; then
      mise install "brew@${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "asdf" ]; then
      asdf install brew "${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "brew@${VERSION}"
    elif [ "$BREW_INSTALL_METHOD" = "vfox" ]; then
      vfox add brew || true
      vfox install "brew@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/brew/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing brew ${VERSION} natively to ${TARGET_DIR}..."
        if [ -f /etc/alpine-release ]; then
          log_info "Homebrew is not supported on Alpine Linux (musl)."
          mkdir -p "${TARGET_DIR}/bin"
          echo '#!/bin/sh' > "${TARGET_DIR}/bin/brew"
          echo 'echo "Homebrew is not supported on Alpine Linux (musl)."' >> "${TARGET_DIR}/bin/brew"
          chmod +x "${TARGET_DIR}/bin/brew"
        else
          if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
            libscript_depends "build-essential" "procps" "curl" "file" "git" || true
          fi
          mkdir -p "${TARGET_DIR}/brew"
          curl -sL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "${TARGET_DIR}/brew"
          mkdir -p "${TARGET_DIR}/bin"
          ln -sf "${TARGET_DIR}/brew/bin/brew" "${TARGET_DIR}/bin/brew"
        fi
      else
        log_info "brew ${VERSION} is already installed."
      fi
      libscript_symlink_alias "brew" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$BREW_INSTALL_METHOD" = "libscript_native" ] || [ "$BREW_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-brew}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $BREW_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$BREW_INSTALL_METHOD" = "libscript_native" ] || [ "$BREW_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-brew}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $BREW_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$BREW_INSTALL_METHOD" = "libscript_native" ] || [ "$BREW_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-brew}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $BREW_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$BREW_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling brew $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/brew/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/brew/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $BREW_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
