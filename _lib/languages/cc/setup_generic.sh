#!/bin/sh
# ## Overview
# Generic setup module for cc.
# 
# ## Usage
# Execute this script to perform generic initialization steps for cc.

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
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

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

CC_INSTALL_METHOD="$(libscript_resolve_install_method "CC")"
ACTION="${ACTION:-install}"
VERSION="${CC_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote cc 2>/dev/null | tail -n 1)
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
    if [ "$CC_INSTALL_METHOD" = "mise" ]; then
      mise ls cc || true
    elif [ "$CC_INSTALL_METHOD" = "asdf" ]; then
      asdf list cc || true
    elif [ "$CC_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CC_INSTALL_METHOD" = "vfox" ]; then
      vfox ls cc || true
    elif [ "$CC_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$CC_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote cc || true
    elif [ "$CC_INSTALL_METHOD" = "asdf" ]; then
      asdf list all cc || true
    elif [ "$CC_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$CC_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all cc || true
    else
      if [ -n "${CC_RELEASES_URL:-}" ]; then
        curl -sSL "${CC_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/gcc-mirror/gcc" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$CC_INSTALL_METHOD" = "mise" ]; then
      mise use "cc@${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "asdf" ]; then
      asdf global cc "${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$CC_INSTALL_METHOD" = "vfox" ]; then
      vfox use "cc@${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "vfox" ]; then
      vfox use "cc@${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "cc" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "cc" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "cc ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "cc" "default" "${EXACT_VERSION}"
      log_info "Set default cc version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env cc \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading cc ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc"
      if [ -n "${CC_DOWNLOAD_URL:-}" ]; then
        curl -sSL "${CC_DOWNLOAD_URL}" -o "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/cc-${VERSION}.tar.gz"
      else
        printf '%s\n' "CC_DOWNLOAD_URL is not defined. Skipping."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$CC_INSTALL_METHOD" = "system" ]; then
      libscript_depends "cc"
    elif [ "$CC_INSTALL_METHOD" = "mise" ]; then
      mise install "cc@${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "asdf" ]; then
      asdf install cc "${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "cc@${VERSION}"
    elif [ "$CC_INSTALL_METHOD" = "vfox" ]; then
      vfox add cc || true
      vfox install "cc@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing cc ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/cc" || true
              chmod +x "${TARGET_DIR}/bin/cc" || true
            fi
          fi
        else
          if [ -n "${CC_DOWNLOAD_URL:-}" ]; then
            curl -sSL "${CC_DOWNLOAD_URL}" | tar -xzf - -C "${TARGET_DIR}" --strip-components=1 || true
          else
            log_warn "No download URL provided for cc ${VERSION}."
          fi
        fi
      else
        log_info "cc ${VERSION} is already installed."
      fi
      libscript_symlink_alias "cc" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ] || [ "$CC_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cc}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $CC_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ] || [ "$CC_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cc}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $CC_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ] || [ "$CC_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cc}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $CC_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling cc $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $CC_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
