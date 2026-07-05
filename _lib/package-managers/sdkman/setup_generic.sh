#!/bin/sh
# ## Overview
# Generic setup module for sdkman.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
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

SDKMAN_INSTALL_METHOD="$(libscript_resolve_install_method "SDKMAN")"
ACTION="${ACTION:-install}"
VERSION="${SDKMAN_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote sdkman 2>/dev/null | tail -n 1)
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
    if [ "$SDKMAN_INSTALL_METHOD" = "mise" ]; then
      mise ls sdkman || true
    elif [ "$SDKMAN_INSTALL_METHOD" = "asdf" ]; then
      asdf list sdkman || true
    elif [ "$SDKMAN_INSTALL_METHOD" = "pkgx" ]; then
      echo "pkgx does not have a local list command"
    elif [ "$SDKMAN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls sdkman || true
    elif [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      echo "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sdkman/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SDKMAN_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote sdkman || true
    elif [ "$SDKMAN_INSTALL_METHOD" = "asdf" ]; then
      asdf list all sdkman || true
    elif [ "$SDKMAN_INSTALL_METHOD" = "pkgx" ]; then
      echo "pkgx does not have a local list command"
    elif [ "$SDKMAN_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all sdkman || true
    else
      if [ -n "${SDKMAN_RELEASES_URL:-}" ]; then
        curl -sSL "${SDKMAN_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || echo "No versions found"
      else
      git ls-remote --tags "https://github.com/sdkman/sdkman-cli" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || echo "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$SDKMAN_INSTALL_METHOD" = "mise" ]; then
      mise use "sdkman@${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "asdf" ]; then
      asdf global sdkman "${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "pkgx" ]; then
      echo "pkgx does not use explicit versions this way"
    elif [ "$SDKMAN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "sdkman@${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "vfox" ]; then
      vfox use "sdkman@${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      echo "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "sdkman" "$VERSION" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download)
    if [ "$SDKMAN_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading sdkman ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sdkman..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sdkman"
      if [ -n "${SDKMAN_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SDKMAN_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sdkman/sdkman-${VERSION}.tar.gz"
      else
        log_warn "SDKMAN_DOWNLOAD_URL is not defined for sdkman ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      libscript_depends "sdkman"
    elif [ "$SDKMAN_INSTALL_METHOD" = "mise" ]; then
      mise install "sdkman@${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "asdf" ]; then
      asdf install sdkman "${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "sdkman@${VERSION}"
    elif [ "$SDKMAN_INSTALL_METHOD" = "vfox" ]; then
      vfox add sdkman || true
      vfox install "sdkman@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sdkman/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing sdkman ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sdkman/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sdkman/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/sdkman" || true
              chmod +x "${TARGET_DIR}/bin/sdkman" || true
            fi
          fi
        else
          if [ -n "${SDKMAN_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${SDKMAN_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${SDKMAN_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${SDKMAN_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/sdkman" || true
              chmod +x "${TARGET_DIR}/bin/sdkman" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_warn "No download URL provided for sdkman ${VERSION}."
          fi
        fi
      else
        log_info "sdkman ${VERSION} is already installed."
      fi
      libscript_symlink_alias "sdkman" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$SDKMAN_INSTALL_METHOD" = "libscript_native" ] || [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sdkman}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $SDKMAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$SDKMAN_INSTALL_METHOD" = "libscript_native" ] || [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sdkman}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $SDKMAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$SDKMAN_INSTALL_METHOD" = "libscript_native" ] || [ "$SDKMAN_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sdkman}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $SDKMAN_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$SDKMAN_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling sdkman $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/sdkman/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/sdkman/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $SDKMAN_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
