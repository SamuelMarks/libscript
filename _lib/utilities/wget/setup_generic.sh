#!/bin/sh
# ## Overview
# Generic setup script for the wget component.
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

WGET_INSTALL_METHOD="${WGET_INSTALL_METHOD:-system}"
WGET_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$WGET_INSTALL_METHOD" libscript_resolve_install_method "WGET")"
WGET_VERSION="${WGET_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${WGET_VERSION}" = "latest" ] || [ "${WGET_VERSION}" = "lts" ]; then
    EXACT_VERSION=$(curl -sL 'https://ftp.gnu.org/gnu/wget/' | grep -o 'wget-[0-9.]*\.tar\.gz' | tail -n1 | sed 's/wget-//' | sed 's/\.tar\.gz//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${WGET_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${WGET_INSTALL_METHOD}" = "mise" ]; then
      mise ls wget
    elif [ "${WGET_INSTALL_METHOD}" = "asdf" ]; then
      asdf list wget
    elif [ "${WGET_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${WGET_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls wget
    elif [ "${WGET_INSTALL_METHOD}" = "system" ]; then
      wget --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/wget/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${WGET_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote wget
    elif [ "${WGET_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all wget
    elif [ "${WGET_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${WGET_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all wget
    elif [ "${WGET_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for wget"
    fi
    exit 0
    ;;
  use)
    if [ "${WGET_INSTALL_METHOD}" = "mise" ]; then
      mise use "wget@${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "asdf" ]; then
      asdf global wget "${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${WGET_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "wget@${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "wget" "${WGET_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "wget" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wget/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "wget ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "wget" "default" "${EXACT_VERSION}"
      log_info "Set default wget version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env wget \"${WGET_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$WGET_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading wget ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wget..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wget"
      if [ -n "${WGET_DOWNLOAD_URL:-}" ]; then
        libscript_download "${WGET_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wget/wget-${VERSION:-}.tar.gz"
      else
        log_warn "WGET_DOWNLOAD_URL is not defined for wget ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${WGET_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'wget'
    elif [ "${WGET_INSTALL_METHOD}" = "mise" ]; then
      mise install "wget@${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "asdf" ]; then
      asdf install wget "${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "wget@${WGET_VERSION}"
    elif [ "${WGET_INSTALL_METHOD}" = "vfox" ]; then
      vfox add wget || true
      vfox install "wget@${WGET_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wget/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/wget" ]; then
        libscript_symlink_alias "wget" "${WGET_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wget/"*"${VERSION:-}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wget/" -maxdepth 1 -type f -name "*${VERSION:-}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/wget" || true
            chmod +x "${TARGET_DIR}/bin/wget" || true
          fi
        fi
      else
        if [ -n "${WGET_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${WGET_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${WGET_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${WGET_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/wget" || true
            chmod +x "${TARGET_DIR}/bin/wget" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_error "No download URL provided for wget ${VERSION:-}."
          exit 1
        fi
      fi
      
      libscript_symlink_alias "wget" "${WGET_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$WGET_INSTALL_METHOD" = "libscript_native" ] || [ "$WGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wget}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $WGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$WGET_INSTALL_METHOD" = "libscript_native" ] || [ "$WGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wget}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $WGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$WGET_INSTALL_METHOD" = "libscript_native" ] || [ "$WGET_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wget}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $WGET_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$WGET_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling wget $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/wget/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/wget/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $WGET_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
