#!/bin/sh
# ## Overview
# Generic setup script for the dash component.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

set -feu
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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
done

DASH_INSTALL_METHOD="${DASH_INSTALL_METHOD:-system}"
DASH_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$DASH_INSTALL_METHOD" libscript_resolve_install_method "DASH")"
DASH_VERSION="${DASH_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${DASH_VERSION}" = "latest" ] || [ "${DASH_VERSION}" = "lts" ]; then
    EXACT_VERSION="0.5.12"
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${DASH_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${DASH_INSTALL_METHOD}" = "mise" ]; then
      mise ls dash
    elif [ "${DASH_INSTALL_METHOD}" = "asdf" ]; then
      asdf list dash
    elif [ "${DASH_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${DASH_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls dash
    elif [ "${DASH_INSTALL_METHOD}" = "system" ]; then
      dash --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/dash/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${DASH_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote dash
    elif [ "${DASH_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all dash
    elif [ "${DASH_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${DASH_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all dash
    elif [ "${DASH_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for dash"
    fi
    exit 0
    ;;
  use)
    if [ "${DASH_INSTALL_METHOD}" = "mise" ]; then
      mise use "dash@${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "asdf" ]; then
      asdf global dash "${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${DASH_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "dash@${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "dash" "${DASH_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "dash" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/dash/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "dash ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "dash" "default" "${EXACT_VERSION}"
      log_info "Set default dash version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env dash \"${DASH_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$DASH_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading dash ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash"
      if [ -n "${DASH_DOWNLOAD_URL:-}" ]; then
        libscript_download "${DASH_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash/dash-${VERSION:-}.tar.gz"
      else
        log_warn "DASH_DOWNLOAD_URL is not defined for dash ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${DASH_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'dash'
    elif [ "${DASH_INSTALL_METHOD}" = "mise" ]; then
      mise install "dash@${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "asdf" ]; then
      asdf install dash "${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "dash@${DASH_VERSION}"
    elif [ "${DASH_INSTALL_METHOD}" = "vfox" ]; then
      vfox add dash || true
      vfox install "dash@${DASH_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/dash/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/dash" ]; then
        libscript_symlink_alias "dash" "${DASH_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash/"*"${VERSION:-}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash/" -maxdepth 1 -type f -name "*${VERSION:-}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/dash" || true
            chmod +x "${TARGET_DIR}/bin/dash" || true
          fi
        fi
      else
        if [ -n "${DASH_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${DASH_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${DASH_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${DASH_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/dash" || true
            chmod +x "${TARGET_DIR}/bin/dash" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_error "No download URL provided for dash ${VERSION:-}."
          exit 1
        fi
      fi
      
      libscript_symlink_alias "dash" "${DASH_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$DASH_INSTALL_METHOD" = "libscript_native" ] || [ "$DASH_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-dash}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $DASH_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$DASH_INSTALL_METHOD" = "libscript_native" ] || [ "$DASH_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-dash}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $DASH_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$DASH_INSTALL_METHOD" = "libscript_native" ] || [ "$DASH_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-dash}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $DASH_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$DASH_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling dash $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/dash/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/dash/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $DASH_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
