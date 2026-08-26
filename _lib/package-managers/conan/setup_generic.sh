#!/bin/sh
# ## Overview
# Generic setup module for conan.
# 
# ## Usage
# Execute this script to perform generic initialization steps for conan.

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

CONAN_INSTALL_METHOD="$(libscript_resolve_install_method "CONAN")"
ACTION="${ACTION:-install}"
VERSION="${CONAN_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote conan 2>/dev/null | tail -n 1)
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
    if [ "$CONAN_INSTALL_METHOD" = "mise" ]; then
      mise ls conan || true
    elif [ "$CONAN_INSTALL_METHOD" = "asdf" ]; then
      asdf list conan || true
    elif [ "$CONAN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CONAN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls conan || true
    elif [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$CONAN_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote conan || true
    elif [ "$CONAN_INSTALL_METHOD" = "asdf" ]; then
      asdf list all conan || true
    elif [ "$CONAN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CONAN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all conan || true
    else
      if [ -n "${CONAN_RELEASES_URL:-}" ]; then
        curl -sSL "${CONAN_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/conan-io/conan" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$CONAN_INSTALL_METHOD" = "mise" ]; then
      mise use "conan@${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "asdf" ]; then
      asdf global conan "${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$CONAN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "conan@${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "conan@${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "conan" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "conan" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "conan ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "conan" "default" "${EXACT_VERSION}"
      log_info "Set default conan version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env conan \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading conan ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan"
      if [ -n "${CONAN_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CONAN_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan/conan-${VERSION}.tar.gz"
      else
        log_warn "CONAN_DOWNLOAD_URL is not defined for conan ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      libscript_depends "conan"
    elif [ "$CONAN_INSTALL_METHOD" = "mise" ]; then
      mise install "conan@${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "asdf" ]; then
      asdf install conan "${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "conan@${VERSION}"
    elif [ "$CONAN_INSTALL_METHOD" = "vfox" ]; then
      vfox add conan || true
      vfox install "conan@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing conan ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends "python" "python3-venv" || true
        if ! type libscript_python_venv >/dev/null 2>&1; then
          . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        fi
        libscript_python_venv "${TARGET_DIR}/venv"
        if [ "$UNAME_LOWER" = "freebsd" ]; then
          libscript_depends "gcc" "make" "python3"
        elif [ -f /etc/alpine-release ]; then
          libscript_depends "gcc" "musl-dev" "python3-dev" "libffi-dev" "openssl-dev" "make"
        fi
        "${TARGET_DIR}/venv/bin/pip" install conan
        mkdir -p "${TARGET_DIR}/bin"
        ln -sf "${TARGET_DIR}/venv/bin/conan" "${TARGET_DIR}/bin/conan"
      else
        log_info "conan ${VERSION} is already installed."
      fi
      libscript_symlink_alias "conan" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ] || [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-conan}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $CONAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ] || [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-conan}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $CONAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ] || [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-conan}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $CONAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling conan $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $CONAN_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
