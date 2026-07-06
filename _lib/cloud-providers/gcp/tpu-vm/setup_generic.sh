#!/bin/sh

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
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# Attempt to install via the detected package manager
ACTION="${ACTION:-install}"
VERSION="${TPU_VM_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote tpu-vm 2>/dev/null | tail -n 1)
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
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/tpu-vm/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/google/jax" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || echo "No versions found"
    exit 0
    ;;
  use)
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "tpu-vm" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "tpu-vm" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/tpu-vm/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "tpu-vm ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "tpu-vm" "default" "${EXACT_VERSION}"
      log_info "Set default tpu-vm version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env tpu-vm \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$TPU_VM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading tpu-vm ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tpu-vm..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tpu-vm"
      if [ -n "${TPU_VM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${TPU_VM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tpu-vm/tpu-vm-${VERSION}.tar.gz"
      else
        log_warn "TPU_VM_DOWNLOAD_URL is not defined for tpu-vm ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/tpu-vm/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing tpu-vm ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tpu-vm/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tpu-vm/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/tpu-vm" || true
            chmod +x "${TARGET_DIR}/bin/tpu-vm" || true
          fi
        fi
      else
        if [ -n "${TPU_VM_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${TPU_VM_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${TPU_VM_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${TPU_VM_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/tpu-vm" || true
            chmod +x "${TARGET_DIR}/bin/tpu-vm" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_warn "No download URL provided for tpu-vm ${VERSION}."
        fi
      fi
    else
      log_info "tpu-vm ${VERSION} is already installed."
    fi
    libscript_symlink_alias "tpu-vm" "$VERSION" "${EXACT_VERSION}"

    ;;

  start|stop|restart|status|health|logs|up|down)
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${TPU_VM_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for ${TPU_VM_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  install-service)
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${TPU_VM_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for ${TPU_VM_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "libscript_native" ] || [ "${TPU_VM_INSTALL_METHOD:-}" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for ${TPU_VM_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  uninstall)
    if [ "${TPU_VM_INSTALL_METHOD:-}" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling ${PACKAGE_NAME:-component} $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/${PACKAGE_NAME:-component}/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/${PACKAGE_NAME:-component}/$VERSION"
    else
      log_info "Uninstall not implemented or supported for ${TPU_VM_INSTALL_METHOD:-}."
    fi
    exit 0
    ;;
  *)
    log_info "Unknown action: $ACTION"
    exit 1
    ;;
esac
