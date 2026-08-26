#!/bin/sh
# ## Overview
# Generic setup script for the httpd component.
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

HTTPD_INSTALL_METHOD="${HTTPD_INSTALL_METHOD:-system}"
HTTPD_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$HTTPD_INSTALL_METHOD" libscript_resolve_install_method "HTTPD")"
HTTPD_VERSION="${HTTPD_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${HTTPD_VERSION}" = "latest" ] || [ "${HTTPD_VERSION}" = "lts" ]; then
    EXACT_VERSION="2.4.58"
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${HTTPD_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${HTTPD_INSTALL_METHOD}" = "mise" ]; then
      mise ls httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "asdf" ]; then
      asdf list httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${HTTPD_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      httpd --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${HTTPD_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${HTTPD_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all httpd
    elif [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for httpd"
    fi
    exit 0
    ;;
  use)
    if [ "${HTTPD_INSTALL_METHOD}" = "mise" ]; then
      mise use "httpd@${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "asdf" ]; then
      asdf global httpd "${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${HTTPD_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "httpd@${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "httpd" "${HTTPD_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "httpd" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "httpd ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "httpd" "default" "${EXACT_VERSION}"
      log_info "Set default httpd version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env httpd \"${HTTPD_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$HTTPD_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading httpd ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/httpd..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/httpd"
      if [ -n "${HTTPD_DOWNLOAD_URL:-}" ]; then
        libscript_download "${HTTPD_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/httpd/httpd-${VERSION}.tar.gz"
      else
        log_warn "HTTPD_DOWNLOAD_URL is not defined for httpd ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'httpd'
    elif [ "${HTTPD_INSTALL_METHOD}" = "mise" ]; then
      mise install "httpd@${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "asdf" ]; then
      asdf install httpd "${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "httpd@${HTTPD_VERSION}"
    elif [ "${HTTPD_INSTALL_METHOD}" = "vfox" ]; then
      vfox add httpd || true
      vfox install "httpd@${HTTPD_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/httpd" ]; then
        libscript_symlink_alias "httpd" "${HTTPD_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      if [ "$UNAME_LOWER" = "linux" ] && [ -n "${PKG_MGR:-}" ]; then
        log_info "Falling back to system package manager for httpd..."
        libscript_depends "httpd"
      else
        log_error "Native installation for httpd from source is not supported yet."
        exit 1
      fi
      
      libscript_symlink_alias "httpd" "${HTTPD_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$HTTPD_INSTALL_METHOD" = "libscript_native" ] || [ "$HTTPD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-httpd}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $HTTPD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$HTTPD_INSTALL_METHOD" = "libscript_native" ] || [ "$HTTPD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-httpd}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $HTTPD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$HTTPD_INSTALL_METHOD" = "libscript_native" ] || [ "$HTTPD_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-httpd}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $HTTPD_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$HTTPD_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling httpd $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $HTTPD_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
