#!/bin/sh
# ## Overview
# Generic setup module for mosquitto.
# 
# ## Usage
# Execute this script to perform generic initialization steps for mosquitto.

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

MOSQUITTO_INSTALL_METHOD="$(libscript_resolve_install_method "MOSQUITTO")"
ACTION="${ACTION:-install}"
VERSION="${MOSQUITTO_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote mosquitto 2>/dev/null | tail -n 1)
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
    if [ "$MOSQUITTO_INSTALL_METHOD" = "mise" ]; then
      mise ls mosquitto || true
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "asdf" ]; then
      asdf list mosquitto || true
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "vfox" ]; then
      vfox ls mosquitto || true
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/mosquitto/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote mosquitto || true
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "asdf" ]; then
      asdf list all mosquitto || true
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all mosquitto || true
    else
      if [ -n "${MOSQUITTO_RELEASES_URL:-}" ]; then
        curl -sSL "${MOSQUITTO_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/mosquitto" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "mise" ]; then
      mise use "mosquitto@${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "asdf" ]; then
      asdf global mosquitto "${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "vfox" ]; then
      vfox use "mosquitto@${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "vfox" ]; then
      vfox use "mosquitto@${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "mosquitto" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "mosquitto" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mosquitto/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "mosquitto ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "mosquitto" "default" "${EXACT_VERSION}"
      log_info "Set default mosquitto version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env mosquitto \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading mosquitto ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mosquitto..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mosquitto"
      if [ -n "${MOSQUITTO_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MOSQUITTO_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mosquitto/mosquitto-${VERSION}.tar.gz"
      else
        log_warn "MOSQUITTO_DOWNLOAD_URL is not defined for mosquitto ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      libscript_depends "mosquitto"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "mise" ]; then
      mise install "mosquitto@${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "asdf" ]; then
      asdf install mosquitto "${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "mosquitto@${VERSION}"
    elif [ "$MOSQUITTO_INSTALL_METHOD" = "vfox" ]; then
      vfox add mosquitto || true
      vfox install "mosquitto@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mosquitto/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing mosquitto ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mosquitto/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mosquitto/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/mosquitto" || true
              chmod +x "${TARGET_DIR}/bin/mosquitto" || true
            fi
          fi
        else
          if [ -n "${MOSQUITTO_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${MOSQUITTO_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${MOSQUITTO_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${MOSQUITTO_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/mosquitto" || true
              chmod +x "${TARGET_DIR}/bin/mosquitto" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_warn "No download URL provided for mosquitto ${VERSION}."
          fi
        fi
      else
        log_info "mosquitto ${VERSION} is already installed."
      fi
      libscript_symlink_alias "mosquitto" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "libscript_native" ] || [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-mosquitto}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $MOSQUITTO_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "libscript_native" ] || [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-mosquitto}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $MOSQUITTO_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "libscript_native" ] || [ "$MOSQUITTO_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-mosquitto}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $MOSQUITTO_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$MOSQUITTO_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling mosquitto $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/mosquitto/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/mosquitto/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $MOSQUITTO_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
