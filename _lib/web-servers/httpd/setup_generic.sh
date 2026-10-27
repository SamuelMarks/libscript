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
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${HTTPD_VERSION}" = "latest" ] || [ "${HTTPD_VERSION}" = "lts" ]; then
    EXACT_VERSION='2.4.58'
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION='latest'
    fi
  else
    EXACT_VERSION="${HTTPD_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      httpd --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      printf '%s\n' 'Fetching remote versions not implemented generically for httpd'
    fi
    exit 0
    ;;
  use)
    if [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
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
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env httpd \"${HTTPD_VERSION}\")"
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
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${VERSION:-latest}/bin/httpd" ]; then
      log_info "httpd ${VERSION:-latest} is already installed."
      exit 0
    fi

    if [ "${HTTPD_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'httpd'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/httpd/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/httpd" ]; then
        libscript_symlink_alias "httpd" "${HTTPD_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
        log_info 'Falling back to system package manager for httpd...'
        libscript_depends 'httpd'
        mkdir -p "${TARGET_DIR}/bin"
        for bin_name in httpd apache2; do
          sys_bin=""
          if command -v "$bin_name" >/dev/null 2>&1; then
            sys_bin=$(command -v "$bin_name")
          elif [ -x "/usr/sbin/$bin_name" ]; then
            sys_bin="/usr/sbin/$bin_name"
          fi
          if [ -n "$sys_bin" ]; then
            ln -sf "$sys_bin" "${TARGET_DIR}/bin/httpd"
            ln -sf "$sys_bin" "${TARGET_DIR}/bin/apache2"
            break
          fi
        done
      else
        log_error 'Native installation for httpd from source is not supported yet.'
        exit 1
      fi
      
      libscript_symlink_alias "httpd" "${HTTPD_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "httpd" "$ACTION" "$VERSION" "${HTTPD_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
