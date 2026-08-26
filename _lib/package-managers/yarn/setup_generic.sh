#!/bin/sh
# ## Overview
# Generic setup module for yarn.
# 
# ## Usage
# Execute this script to perform generic initialization steps for yarn.

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

YARN_INSTALL_METHOD="${YARN_INSTALL_METHOD:-system}"
YARN_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$YARN_INSTALL_METHOD" libscript_resolve_install_method "YARN")"
ACTION="${ACTION:-install}"
VERSION="${YARN_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote yarn 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION=$(curl -sL https://api.github.com/repos/yarnpkg/yarn/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$YARN_INSTALL_METHOD" = "mise" ]; then
      mise ls yarn || true
    elif [ "$YARN_INSTALL_METHOD" = "asdf" ]; then
      asdf list yarn || true
    elif [ "$YARN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$YARN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls yarn || true
    elif [ "$YARN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/yarn/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$YARN_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote yarn || true
    elif [ "$YARN_INSTALL_METHOD" = "asdf" ]; then
      asdf list all yarn || true
    elif [ "$YARN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$YARN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all yarn || true
    else
      if [ -n "${YARN_RELEASES_URL:-}" ]; then
        curl -sSL "${YARN_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/yarn" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$YARN_INSTALL_METHOD" = "mise" ]; then
      mise use "yarn@${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "asdf" ]; then
      asdf global yarn "${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$YARN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "yarn@${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "yarn@${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "yarn" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "yarn" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/yarn/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "yarn ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "yarn" "default" "${EXACT_VERSION}"
      log_info "Set default yarn version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env yarn \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$YARN_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading yarn ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yarn..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yarn"
      if [ -n "${YARN_DOWNLOAD_URL:-}" ]; then
        libscript_download "${YARN_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yarn/yarn-${VERSION}.tar.gz"
      else
        log_warn "YARN_DOWNLOAD_URL is not defined for yarn ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$YARN_INSTALL_METHOD" = "system" ]; then
      libscript_depends "yarn"
    elif [ "$YARN_INSTALL_METHOD" = "mise" ]; then
      mise install "yarn@${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "asdf" ]; then
      asdf install yarn "${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "yarn@${VERSION}"
    elif [ "$YARN_INSTALL_METHOD" = "vfox" ]; then
      vfox add yarn || true
      vfox install "yarn@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/yarn/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing yarn ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yarn/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yarn/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/yarn" || true
              chmod +x "${TARGET_DIR}/bin/yarn" || true
            fi
          fi
        else
          URL="https://github.com/yarnpkg/yarn/releases/download/v${EXACT_VERSION}/yarn-v${EXACT_VERSION}.tar.gz"
          TEMP_FILE=$(mktemp)
          libscript_depends "curl" "tar" || true
          if ! curl -sSLf "$URL" -o "$TEMP_FILE.tar.gz"; then
            log_error "Failed to download yarn from $URL"
            rm -f "$TEMP_FILE.tar.gz"
            exit 1
          fi
          tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}" --strip-components=1 || true
          ln -sf "${TARGET_DIR}/bin/yarn" "${TARGET_DIR}/bin/yarnpkg" || true
          rm -f "$TEMP_FILE.tar.gz"
        fi
      else
        log_info "yarn ${VERSION} is already installed."
      fi
      libscript_symlink_alias "yarn" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$YARN_INSTALL_METHOD" = "libscript_native" ] || [ "$YARN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-yarn}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $YARN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$YARN_INSTALL_METHOD" = "libscript_native" ] || [ "$YARN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-yarn}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $YARN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$YARN_INSTALL_METHOD" = "libscript_native" ] || [ "$YARN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-yarn}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $YARN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$YARN_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling yarn $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/yarn/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/yarn/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $YARN_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
