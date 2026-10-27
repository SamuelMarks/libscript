#!/bin/sh
# ## Overview
# Generic setup script for the lighttpd component.
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

LIGHTTPD_INSTALL_METHOD="${LIGHTTPD_INSTALL_METHOD:-system}"
LIGHTTPD_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$LIGHTTPD_INSTALL_METHOD" libscript_resolve_install_method "LIGHTTPD")"
LIGHTTPD_VERSION="${LIGHTTPD_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${LIGHTTPD_VERSION}" = "latest" ] || [ "${LIGHTTPD_VERSION}" = "lts" ]; then
    EXACT_VERSION='1.4.74'
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION='latest'
    fi
  else
    EXACT_VERSION="${LIGHTTPD_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${LIGHTTPD_INSTALL_METHOD}" = "system" ]; then
      lighttpd --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/lighttpd/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${LIGHTTPD_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      printf '%s\n' 'Fetching remote versions not implemented generically for lighttpd'
    fi
    exit 0
    ;;
  use)
    if [ "${LIGHTTPD_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "lighttpd" "${LIGHTTPD_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "lighttpd" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/lighttpd/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "lighttpd ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "lighttpd" "default" "${EXACT_VERSION}"
      log_info "Set default lighttpd version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env lighttpd \"${LIGHTTPD_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$LIGHTTPD_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading lighttpd ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lighttpd..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lighttpd"
      if [ -n "${LIGHTTPD_DOWNLOAD_URL:-}" ]; then
        libscript_download "${LIGHTTPD_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lighttpd/lighttpd-${VERSION}.tar.gz"
      else
        log_warn "LIGHTTPD_DOWNLOAD_URL is not defined for lighttpd ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/lighttpd/${VERSION:-latest}/bin/lighttpd" ]; then
      log_info "lighttpd ${VERSION:-latest} is already installed."
      exit 0
    fi
    if [ "${LIGHTTPD_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'lighttpd'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/lighttpd/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/lighttpd" ]; then
        libscript_symlink_alias "lighttpd" "${LIGHTTPD_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lighttpd/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info 'Extracting from cache...'
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/lighttpd/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/lighttpd" || true
            chmod +x "${TARGET_DIR}/bin/lighttpd" || true
          fi
        fi
      else
        if [ -n "${LIGHTTPD_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${LIGHTTPD_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${LIGHTTPD_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${LIGHTTPD_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/lighttpd" || true
            chmod +x "${TARGET_DIR}/bin/lighttpd" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_error "No download URL provided for lighttpd ${VERSION}."
          exit 1
        fi
      fi
      
      libscript_symlink_alias "lighttpd" "${LIGHTTPD_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "lighttpd" "$ACTION" "$VERSION" "${LIGHTTPD_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
