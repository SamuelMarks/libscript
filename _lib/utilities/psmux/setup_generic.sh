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
DIR="${SCRIPT_DIR}"

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
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${PSMUX_VERSION}" = "latest" ] || [ "${PSMUX_VERSION}" = "lts" ]; then
    EXACT_VERSION="0.1.0"
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${PSMUX_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${PSMUX_INSTALL_METHOD}" = "mise" ]; then
      mise ls psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "asdf" ]; then
      asdf list psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${PSMUX_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      psmux --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${PSMUX_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${PSMUX_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all psmux
    elif [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for psmux"
    fi
    exit 0
    ;;
  use)
    if [ "${PSMUX_INSTALL_METHOD}" = "mise" ]; then
      mise use "psmux@${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "asdf" ]; then
      asdf global psmux "${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${PSMUX_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "psmux@${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
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
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env psmux \"${PSMUX_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading psmux ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux"
      if [ -n "${PSMUX_DOWNLOAD_URL:-}" ]; then
        libscript_download "${PSMUX_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/psmux-${VERSION}.tar.gz"
      else
        log_warn "PSMUX_DOWNLOAD_URL is not defined for psmux ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)

    if [ "${PSMUX_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'psmux'
    elif [ "${PSMUX_INSTALL_METHOD}" = "mise" ]; then
      mise install "psmux@${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "asdf" ]; then
      asdf install psmux "${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "psmux@${PSMUX_VERSION}"
    elif [ "${PSMUX_INSTALL_METHOD}" = "vfox" ]; then
      vfox add psmux || true
      vfox install "psmux@${PSMUX_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/psmux" ]; then
        libscript_symlink_alias "psmux" "${PSMUX_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/psmux/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
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
          log_warn "No download URL provided for psmux ${VERSION}."
          # Fallback to mock
          printf '%s\n' "#!/bin/sh" > "${TARGET_DIR}/bin/psmux"
          printf '%s\n' "printf '%s\n' 'Mock psmux executable for version ${EXACT_VERSION}'" >> "${TARGET_DIR}/bin/psmux"
          chmod +x "${TARGET_DIR}/bin/psmux"
        fi
      fi
      
      libscript_symlink_alias "psmux" "${PSMUX_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ] || [ "$PSMUX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-psmux}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $PSMUX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ] || [ "$PSMUX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-psmux}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $PSMUX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ] || [ "$PSMUX_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-psmux}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $PSMUX_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$PSMUX_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling psmux $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/psmux/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $PSMUX_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
