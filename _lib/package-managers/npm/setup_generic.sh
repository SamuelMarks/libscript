#!/bin/sh
# ## Overview
# Generic setup module for npm.
# 
# ## Usage
# Execute this script to perform generic initialization steps for npm.

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

NPM_INSTALL_METHOD="$(libscript_resolve_install_method "NPM")"
ACTION="${ACTION:-install}"
VERSION="${NPM_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote npm 2>/dev/null | tail -n 1)
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
    if [ "$NPM_INSTALL_METHOD" = "mise" ]; then
      mise ls npm || true
    elif [ "$NPM_INSTALL_METHOD" = "asdf" ]; then
      asdf list npm || true
    elif [ "$NPM_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$NPM_INSTALL_METHOD" = "vfox" ]; then
      vfox ls npm || true
    elif [ "$NPM_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/npm/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$NPM_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote npm || true
    elif [ "$NPM_INSTALL_METHOD" = "asdf" ]; then
      asdf list all npm || true
    elif [ "$NPM_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$NPM_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all npm || true
    else
      if [ -n "${NPM_RELEASES_URL:-}" ]; then
        curl -sSL "${NPM_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/npm" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$NPM_INSTALL_METHOD" = "mise" ]; then
      mise use "npm@${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "asdf" ]; then
      asdf global npm "${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$NPM_INSTALL_METHOD" = "vfox" ]; then
      vfox use "npm@${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "vfox" ]; then
      vfox use "npm@${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "npm" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "npm" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/npm/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "npm ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "npm" "default" "${EXACT_VERSION}"
      log_info "Set default npm version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env npm \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$NPM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading npm ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/npm..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/npm"
      if [ -n "${NPM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${NPM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/npm/npm-${VERSION}.tar.gz"
      else
        log_warn "NPM_DOWNLOAD_URL is not defined for npm ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$NPM_INSTALL_METHOD" = "system" ]; then
      libscript_depends "npm"
    elif [ "$NPM_INSTALL_METHOD" = "mise" ]; then
      mise install "npm@${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "asdf" ]; then
      asdf install npm "${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "npm@${VERSION}"
    elif [ "$NPM_INSTALL_METHOD" = "vfox" ]; then
      vfox add npm || true
      vfox install "npm@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/npm/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing npm ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/npm/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/npm/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/npm" || true
              chmod +x "${TARGET_DIR}/bin/npm" || true
            fi
          fi
        else
          if [ -n "${NPM_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${NPM_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${NPM_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${NPM_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/npm" || true
              chmod +x "${TARGET_DIR}/bin/npm" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info "Falling back to system package manager for npm..."
              libscript_depends "npm"
              if command -v npm >/dev/null 2>&1; then
                ln -s "$(command -v npm)" "${TARGET_DIR}/bin/npm"
              fi
            else
              log_warn "No download URL provided for npm ${VERSION}."
            fi
          fi
        fi
      else
        log_info "npm ${VERSION} is already installed."
      fi
      libscript_symlink_alias "npm" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$NPM_INSTALL_METHOD" = "libscript_native" ] || [ "$NPM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-npm}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $NPM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$NPM_INSTALL_METHOD" = "libscript_native" ] || [ "$NPM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-npm}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $NPM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$NPM_INSTALL_METHOD" = "libscript_native" ] || [ "$NPM_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-npm}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $NPM_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$NPM_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling npm $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/npm/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/npm/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $NPM_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
