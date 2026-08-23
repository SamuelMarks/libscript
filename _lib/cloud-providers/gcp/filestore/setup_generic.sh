#!/bin/sh

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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# # LibScript Common Generic Setup
#
# ## Overview
# This script provides fallback installation logic using the LibScript
# package manager mapper. It is invoked when no OS-specific setup script
# is found for a component.
#
# ## Usage
# Sourced by `setup_base.sh` if `setup_<os>.sh` is missing.

set -feu

# Component name should be set by the caller (component_core.sh sets PACKAGE_NAME)
_PKG_MGR_NAME="${PACKAGE_NAME:-}"

if [ -z "${_PKG_MGR_NAME}" ]; then
  # Fallback: try to get it from the directory name if not set
  _PKG_MGR_NAME=$(basename "$(pwd)")

# ## validate_filestore_config
# Executes validate_filestore_config functionality.
validate_filestore_config() {
  if [ -n "${TPU_ACCELERATOR_TYPE:-}" ] && [ -n "${TPU_VERSION:-}" ]; then
    case "${TPU_ACCELERATOR_TYPE}" in
      v2-*|v3-*)
        case "${TPU_VERSION}" in
          tpu-ubuntu2204-base|filestore-base|filestore-tf-*|filestore-pt-*|filestore-jax-*)
            ;;
          *)
            log_warn "TPU_VERSION ${TPU_VERSION} may be incompatible with ${TPU_ACCELERATOR_TYPE}."
            ;;
        esac
        ;;
      v4-*)
        case "${TPU_VERSION}" in
          tpu-ubuntu2204-base|filestore-v4-base|tpu-ubuntu2204-base-v4|filestore-v4-*)
            ;;
          *)
            log_warn "TPU_VERSION ${TPU_VERSION} may be incompatible with ${TPU_ACCELERATOR_TYPE}."
            ;;
        esac
        ;;
    esac
  fi
}

validate_filestore_config

fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# Attempt to install via the detected package manager
ACTION="${ACTION:-install}"
VERSION="${FILESTORE_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote filestore 2>/dev/null | tail -n 1)
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
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/filestore/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/google/jax" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    exit 0
    ;;
  use)
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "filestore" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "filestore" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/filestore/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "filestore ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "filestore" "default" "${EXACT_VERSION}"
      log_info "Set default filestore version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env filestore \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$FILESTORE_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading filestore ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/filestore..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/filestore"
      if [ -n "${FILESTORE_DOWNLOAD_URL:-}" ]; then
        libscript_download "${FILESTORE_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/filestore/filestore-${VERSION}.tar.gz"
      else
        log_warn "FILESTORE_DOWNLOAD_URL is not defined for filestore ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/filestore/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing filestore ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/filestore/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/filestore/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/filestore" || true
            chmod +x "${TARGET_DIR}/bin/filestore" || true
          fi
        fi
      else
        if [ -n "${FILESTORE_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${FILESTORE_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${FILESTORE_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${FILESTORE_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/filestore" || true
            chmod +x "${TARGET_DIR}/bin/filestore" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_warn "No download URL provided for filestore ${VERSION}."
        fi
      fi
    else
      log_info "filestore ${VERSION} is already installed."
    fi
    libscript_symlink_alias "filestore" "$VERSION" "${EXACT_VERSION}"

    ;;

  start|stop|restart|status|health|logs|up|down)
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${FILESTORE_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for ${FILESTORE_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  install-service)
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${FILESTORE_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for ${FILESTORE_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${FILESTORE_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for ${FILESTORE_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  uninstall)
    if [ "${FILESTORE_INSTALL_METHOD:-}" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling ${PACKAGE_NAME:-component} $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/${PACKAGE_NAME:-component}/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/${PACKAGE_NAME:-component}/$VERSION"
    else
      log_info "Uninstall not implemented or supported for ${FILESTORE_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  *)
    log_info "Unknown action: $ACTION"
    exit 1
    ;;
esac
