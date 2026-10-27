#!/bin/sh
# ## Overview
# Generic setup script for the iis component.
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

IIS_INSTALL_METHOD="$(libscript_resolve_install_method "IIS")"
IIS_VERSION="${IIS_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${IIS_VERSION}" = "latest" ] || [ "${IIS_VERSION}" = "lts" ]; then
    EXACT_VERSION='10.0'
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION='latest'
    fi
  else
    EXACT_VERSION="${IIS_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${IIS_INSTALL_METHOD}" = "system" ]; then
      iis --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/iis/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${IIS_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      printf '%s\n' 'Fetching remote versions not implemented generically for iis'
    fi
    exit 0
    ;;
  use)
    if [ "${IIS_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "iis" "${IIS_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "iis" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/iis/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "iis ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "iis" "default" "${EXACT_VERSION}"
      log_info "Set default iis version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env iis \"${IIS_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$IIS_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading iis ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/iis..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/iis"
      if [ -n "${IIS_DOWNLOAD_URL:-}" ]; then
        libscript_download "${IIS_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/iis/iis-${VERSION}.tar.gz"
      else
        log_warn "IIS_DOWNLOAD_URL is not defined for iis ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/iis/${VERSION:-latest}/bin/iis" ]; then
      log_info "iis ${VERSION:-latest} is already installed."
      exit 0
    fi

    if [ "${IIS_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'iis'
    else
        # libscript_native implementation
        case "$(uname -s)" in
          MINGW*|MSYS*|CYGWIN*|Windows_NT) ;;
          *)
            log_info 'iis is a Windows web server. Skipping.'
            exit 0
            ;;
        esac
      fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "iis" "$ACTION" "$VERSION" "${IIS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
