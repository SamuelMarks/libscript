#!/bin/sh
# ## Overview
# Generic setup script for the psmux component.
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

PSMUX_INSTALL_METHOD="$(libscript_resolve_install_method "PSMUX")"
PSMUX_VERSION="${PSMUX_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${PSMUX_VERSION}" = "latest" ] || [ "${PSMUX_VERSION}" = "lts" ]; then
    EXACT_VERSION='0.1.0'
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION='latest'
    fi
  else
    EXACT_VERSION="${PSMUX_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      psmux --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      printf '%s\n' 'Fetching remote versions not implemented generically for psmux'
    fi
    exit 0
    ;;
  use)
    if [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "psmux" "${PSMUX_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "psmux" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "psmux ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "psmux" "default" "${EXACT_VERSION}"
      log_info "Set default psmux version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env psmux \"${PSMUX_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading psmux ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux"
      if [ -n "${PSMUX_DOWNLOAD_URL:-}" ]; then
        libscript_download "${PSMUX_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/psmux-${VERSION:-}.tar.gz"
      else
        log_warn "PSMUX_DOWNLOAD_URL is not defined for psmux ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/${VERSION:-latest}/bin/psmux" ]; then
      log_info "psmux ${VERSION:-latest} is already installed."
      exit 0
    fi

    if [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'psmux'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/psmux" ]; then
        libscript_symlink_alias "psmux" "${PSMUX_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/"*"${VERSION:-}"* >/dev/null 2>&1; then
        log_info 'Extracting from cache...'
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/" -maxdepth 1 -type f -name "*${VERSION:-}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/psmux" || true
            chmod +x "${TARGET_DIR}/bin/psmux" || true
          fi
        fi
      else
        if [ -n "${PSMUX_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${PSMUX_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${PSMUX_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${PSMUX_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/psmux" || true
            chmod +x "${TARGET_DIR}/bin/psmux" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_error "No download URL provided for psmux ${VERSION:-}."
          exit 1
        fi
      fi
      
      libscript_symlink_alias "psmux" "${PSMUX_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "psmux" "$ACTION" "$VERSION" "${PSMUX_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
