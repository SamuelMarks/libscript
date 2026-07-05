#!/bin/sh
# ## Overview
# Generic setup script for the curl component.
# It provides fallback installation logic and cross-platform installation steps
# when a more specific OS/distribution setup script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.


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
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$THIS_FILE")/../../.." && pwd)}/_lib/_common/pkg_mgr.sh"
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

CURL_INSTALL_METHOD="$(libscript_resolve_install_method "CURL")"
ACTION="${ACTION:-install}"
VERSION="${CURL_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote curl 2>/dev/null | tail -n 1)
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
    if [ "${CURL_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/curl/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/curl/curl" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || echo "No versions found"
    exit 0
    ;;
  use)
    if [ "${CURL_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "curl" "$VERSION" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download)
    if [ "$CURL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading curl ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl"
      if [ -n "${CURL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CURL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl/curl-${VERSION}.tar.gz"
      else
        log_warn "CURL_DOWNLOAD_URL is not defined for curl ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$CURL_INSTALL_METHOD" = "system" ]; then

      if ! command -v curl >/dev/null 2>&1; then
        if ! libscript_depends 'curl'; then
          log_info "Attempting static binary download for curl..."
          ARCH=$(uname -m)
          case "$ARCH" in
            x86_64) BARCH="amd64" ;;
            aarch64|arm64) BARCH="arm64" ;;
            armv7l) BARCH="arm" ;;
            i386|i686) BARCH="i386" ;;
            *) BARCH="amd64" ;;
          esac
          if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl/"*"${VERSION}"* >/dev/null 2>&1; then
            cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
            cp "$cache_file" "/tmp/curl"
          else
            libscript_download "https://github.com/moparisthebest/static-curl/releases/latest/download/curl-${BARCH}" "/tmp/curl" || { printf '%s\n' "Failed to download static curl"; exit 1; }
          fi
          chmod +x /tmp/curl
          if [ -w /usr/local/bin ]; then
            mv /tmp/curl /usr/local/bin/curl
          else
            mkdir -p ~/.local/bin
            mv /tmp/curl ~/.local/bin/curl
          fi
        fi
      fi

    elif [ "$CURL_INSTALL_METHOD" = "libscript_native" ]; then

      if ! command -v curl >/dev/null 2>&1; then
        if ! libscript_depends 'curl'; then
          log_info "Attempting static binary download for curl..."
          ARCH=$(uname -m)
          case "$ARCH" in
            x86_64) BARCH="amd64" ;;
            aarch64|arm64) BARCH="arm64" ;;
            armv7l) BARCH="arm" ;;
            i386|i686) BARCH="i386" ;;
            *) BARCH="amd64" ;;
          esac
          if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl/"*"${VERSION}"* >/dev/null 2>&1; then
            cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/curl/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
            cp "$cache_file" "/tmp/curl"
          else
            libscript_download "https://github.com/moparisthebest/static-curl/releases/latest/download/curl-${BARCH}" "/tmp/curl" || { printf '%s\n' "Failed to download static curl"; exit 1; }
          fi
          chmod +x /tmp/curl
          if [ -w /usr/local/bin ]; then
            mv /tmp/curl /usr/local/bin/curl
          else
            mkdir -p ~/.local/bin
            mv /tmp/curl ~/.local/bin/curl
          fi
        fi
      fi

    else
      >&2 printf 'Method %s not supported\n' "$CURL_INSTALL_METHOD"
      exit 1
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$CURL_INSTALL_METHOD" = "libscript_native" ] || [ "$CURL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-curl}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $CURL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$CURL_INSTALL_METHOD" = "libscript_native" ] || [ "$CURL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-curl}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $CURL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$CURL_INSTALL_METHOD" = "libscript_native" ] || [ "$CURL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-curl}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $CURL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$CURL_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling curl $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/curl/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/curl/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $CURL_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
