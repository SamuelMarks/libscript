#!/bin/sh
# ## Overview
# Generic setup module for systemd.
# 
# ## Usage
# Execute this script to perform generic initialization steps for systemd.

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

SYSTEMD_INSTALL_METHOD="$(libscript_resolve_install_method "SYSTEMD")"
ACTION="${ACTION:-install}"
VERSION="${SYSTEMD_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote systemd 2>/dev/null | tail -n 1)
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
    if [ "$SYSTEMD_INSTALL_METHOD" = "mise" ]; then
      mise ls systemd || true
    elif [ "$SYSTEMD_INSTALL_METHOD" = "asdf" ]; then
      asdf list systemd || true
    elif [ "$SYSTEMD_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "vfox" ]; then
      vfox ls systemd || true
    elif [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/systemd/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SYSTEMD_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote systemd || true
    elif [ "$SYSTEMD_INSTALL_METHOD" = "asdf" ]; then
      asdf list all systemd || true
    elif [ "$SYSTEMD_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all systemd || true
    else
      if [ -n "${SYSTEMD_RELEASES_URL:-}" ]; then
        curl -sSL "${SYSTEMD_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/systemd" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$SYSTEMD_INSTALL_METHOD" = "mise" ]; then
      mise use "systemd@${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "asdf" ]; then
      asdf global systemd "${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "vfox" ]; then
      vfox use "systemd@${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "vfox" ]; then
      vfox use "systemd@${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "systemd" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "systemd" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/systemd/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "systemd ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "systemd" "default" "${EXACT_VERSION}"
      log_info "Set default systemd version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env systemd \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$SYSTEMD_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading systemd ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/systemd..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/systemd"
      if [ -n "${SYSTEMD_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SYSTEMD_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/systemd/systemd-${VERSION}.tar.gz"
      else
        log_warn "SYSTEMD_DOWNLOAD_URL is not defined for systemd ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      libscript_depends "systemd"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "mise" ]; then
      mise install "systemd@${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "asdf" ]; then
      asdf install systemd "${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "systemd@${VERSION}"
    elif [ "$SYSTEMD_INSTALL_METHOD" = "vfox" ]; then
      vfox add systemd || true
      vfox install "systemd@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/systemd/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing systemd ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/systemd/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/systemd/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/systemd" || true
              chmod +x "${TARGET_DIR}/bin/systemd" || true
            fi
          fi
        else
          if [ -n "${SYSTEMD_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${SYSTEMD_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${SYSTEMD_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${SYSTEMD_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/systemd" || true
              chmod +x "${TARGET_DIR}/bin/systemd" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_warn "No download URL provided for systemd ${VERSION}."
          fi
        fi
      else
        log_info "systemd ${VERSION} is already installed."
      fi
      libscript_symlink_alias "systemd" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$SYSTEMD_INSTALL_METHOD" = "libscript_native" ] || [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-systemd}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $SYSTEMD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$SYSTEMD_INSTALL_METHOD" = "libscript_native" ] || [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-systemd}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $SYSTEMD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$SYSTEMD_INSTALL_METHOD" = "libscript_native" ] || [ "$SYSTEMD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-systemd}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $SYSTEMD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$SYSTEMD_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling systemd $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/systemd/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/systemd/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $SYSTEMD_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
