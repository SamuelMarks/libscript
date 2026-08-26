#!/bin/sh
# ## Overview
# Generic setup module for snap.
# 
# ## Usage
# Execute this script to perform generic initialization steps for snap.

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

SNAP_INSTALL_METHOD="$(libscript_resolve_install_method "SNAP")"
ACTION="${ACTION:-install}"
VERSION="${SNAP_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote snap 2>/dev/null | tail -n 1)
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
    if [ "$SNAP_INSTALL_METHOD" = "mise" ]; then
      mise ls snap || true
    elif [ "$SNAP_INSTALL_METHOD" = "asdf" ]; then
      asdf list snap || true
    elif [ "$SNAP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SNAP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls snap || true
    elif [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/snap/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SNAP_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote snap || true
    elif [ "$SNAP_INSTALL_METHOD" = "asdf" ]; then
      asdf list all snap || true
    elif [ "$SNAP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SNAP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all snap || true
    else
      if [ -n "${SNAP_RELEASES_URL:-}" ]; then
        curl -sSL "${SNAP_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/snap-stanford/snap" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$SNAP_INSTALL_METHOD" = "mise" ]; then
      mise use "snap@${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "asdf" ]; then
      asdf global snap "${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$SNAP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "snap@${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "snap@${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "snap" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "snap" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/snap/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "snap ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "snap" "default" "${EXACT_VERSION}"
      log_info "Set default snap version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env snap \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$SNAP_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading snap ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/snap..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/snap"
      if [ -n "${SNAP_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SNAP_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/snap/snap-${VERSION}.tar.gz"
      else
        log_warn "SNAP_DOWNLOAD_URL is not defined for snap ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      libscript_depends "snap"
    elif [ "$SNAP_INSTALL_METHOD" = "mise" ]; then
      mise install "snap@${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "asdf" ]; then
      asdf install snap "${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "snap@${VERSION}"
    elif [ "$SNAP_INSTALL_METHOD" = "vfox" ]; then
      vfox add snap || true
      vfox install "snap@${VERSION}"
    else
      # libscript_native implementation
      if [ -f /etc/alpine-release ]; then
        log_info "snap is not supported on Alpine Linux. Skipping installation."
        exit 0
      fi

      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/snap/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing snap ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if [ "$UNAME_LOWER" = "linux" ] && [ -n "${PKG_MGR:-}" ]; then
          log_info "Falling back to system package manager for snap..."
          libscript_depends "snapd"
        else
          log_error "Native installation for snap from source is not supported."
          exit 1
        fi
      else
        log_info "snap ${VERSION} is already installed."
      fi
      libscript_symlink_alias "snap" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$SNAP_INSTALL_METHOD" = "libscript_native" ] || [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-snap}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $SNAP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$SNAP_INSTALL_METHOD" = "libscript_native" ] || [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-snap}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $SNAP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$SNAP_INSTALL_METHOD" = "libscript_native" ] || [ "$SNAP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-snap}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $SNAP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$SNAP_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling snap $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/snap/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/snap/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $SNAP_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
