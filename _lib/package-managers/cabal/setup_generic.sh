#!/bin/sh
# ## Overview
# Generic setup script for the cabal component.
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

CABAL_INSTALL_METHOD="$(libscript_resolve_install_method "CABAL")"
ACTION="${ACTION:-install}"
VERSION="${CABAL_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote cabal 2>/dev/null | tail -n 1)
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
    if [ "${CABAL_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/cabal/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/haskell/cabal" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || echo "No versions found"
    exit 0
    ;;
  use)
    if [ "${CABAL_INSTALL_METHOD:-}" = "system" ]; then
      echo "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "cabal" "$VERSION" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download)
    if [ "$CABAL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading cabal ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cabal..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cabal"
      if [ -n "${CABAL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CABAL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cabal/cabal-${VERSION}.tar.gz"
      else
        log_warn "CABAL_DOWNLOAD_URL is not defined for cabal ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$CABAL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
      : "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cabal/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Using cached cabal"
      elif ! command -v cabal >/dev/null 2>&1; then
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh" ]; then
          "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh"
          if [ -x "$HOME/.ghcup/bin/cabal" ]; then
            export PATH="$HOME/.ghcup/bin:$PATH"
          fi
        else
          printf "Error: Cannot find ghcup setup script to bootstrap cabal.\n" >&2
          exit 1
        fi
      fi

      if ! command -v cabal >/dev/null 2>&1 && [ -x "$HOME/.ghcup/bin/cabal" ]; then
        export PATH="$HOME/.ghcup/bin:$PATH"
      fi

    elif [ "$CABAL_INSTALL_METHOD" = "libscript_native" ]; then
      SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
      : "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cabal/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Using cached cabal"
      elif ! command -v cabal >/dev/null 2>&1; then
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh" ]; then
          "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/ghcup/setup.sh"
          if [ -x "$HOME/.ghcup/bin/cabal" ]; then
            export PATH="$HOME/.ghcup/bin:$PATH"
          fi
        else
          printf "Error: Cannot find ghcup setup script to bootstrap cabal.\n" >&2
          exit 1
        fi
      fi

      if ! command -v cabal >/dev/null 2>&1 && [ -x "$HOME/.ghcup/bin/cabal" ]; then
        export PATH="$HOME/.ghcup/bin:$PATH"
      fi

    else
      >&2 printf 'Method %s not supported\n' "$CABAL_INSTALL_METHOD"
      exit 1
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$CABAL_INSTALL_METHOD" = "libscript_native" ] || [ "$CABAL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cabal}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $CABAL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$CABAL_INSTALL_METHOD" = "libscript_native" ] || [ "$CABAL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cabal}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $CABAL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$CABAL_INSTALL_METHOD" = "libscript_native" ] || [ "$CABAL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-cabal}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $CABAL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$CABAL_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling cabal $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/cabal/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/cabal/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $CABAL_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
