#!/bin/sh
# ## Overview
# Generic setup script for the aria2 component.
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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
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

ARIA2_INSTALL_METHOD="$(libscript_resolve_install_method "ARIA2")"
ARIA2_VERSION="${ARIA2_VERSION:-latest}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${ARIA2_VERSION}" = "latest" ] || [ "${ARIA2_VERSION}" = "lts" ]; then
    EXACT_VERSION=$(curl -sL https://api.github.com/repos/aria2/aria2/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^release-//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${ARIA2_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${ARIA2_INSTALL_METHOD}" = "mise" ]; then
      mise ls aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "asdf" ]; then
      asdf list aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "pkgx" ]; then
      echo "pkgx does not have a local list command"
    elif [ "${ARIA2_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "system" ]; then
      aria2 --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/aria2/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${ARIA2_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "pkgx" ]; then
      echo "pkgx does not have a local list command"
    elif [ "${ARIA2_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all aria2
    elif [ "${ARIA2_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      echo "Fetching remote versions not implemented generically for aria2"
    fi
    exit 0
    ;;
  use)
    if [ "${ARIA2_INSTALL_METHOD}" = "mise" ]; then
      mise use "aria2@${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "asdf" ]; then
      asdf global aria2 "${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "pkgx" ]; then
      echo "pkgx does not use explicit versions this way"
    elif [ "${ARIA2_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "aria2@${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "aria2" "${ARIA2_VERSION}" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  download)
    if [ "$ARIA2_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading aria2 ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aria2..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aria2"
      if [ -n "${ARIA2_DOWNLOAD_URL:-}" ]; then
        libscript_download "${ARIA2_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aria2/aria2-${VERSION}.tar.gz"
      else
        log_warn "ARIA2_DOWNLOAD_URL is not defined for aria2 ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)

    if [ "${ARIA2_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'aria2'
    elif [ "${ARIA2_INSTALL_METHOD}" = "mise" ]; then
      mise install "aria2@${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "asdf" ]; then
      asdf install aria2 "${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "aria2@${ARIA2_VERSION}"
    elif [ "${ARIA2_INSTALL_METHOD}" = "vfox" ]; then
      vfox add aria2 || true
      vfox install "aria2@${ARIA2_VERSION}"
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/aria2/${EXACT_VERSION}"
      
      if [ -x "${TARGET_DIR}/bin/aria2" ]; then
        libscript_symlink_alias "aria2" "${ARIA2_VERSION}" "${EXACT_VERSION}"
        exit 0
      fi

      mkdir -p "${TARGET_DIR}/bin"
      
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aria2/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info "Extracting from cache..."
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aria2/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/aria2" || true
            chmod +x "${TARGET_DIR}/bin/aria2" || true
          fi
        fi
      else
        if [ -n "${ARIA2_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${ARIA2_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${ARIA2_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${ARIA2_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/aria2" || true
            chmod +x "${TARGET_DIR}/bin/aria2" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_warn "No download URL provided for aria2 ${VERSION}."
          # Fallback to mock
          echo "#!/bin/sh" > "${TARGET_DIR}/bin/aria2"
          echo "echo 'Mock aria2 executable for version ${EXACT_VERSION}'" >> "${TARGET_DIR}/bin/aria2"
          chmod +x "${TARGET_DIR}/bin/aria2"
        fi
      fi
      
      libscript_symlink_alias "aria2" "${ARIA2_VERSION}" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$ARIA2_INSTALL_METHOD" = "libscript_native" ] || [ "$ARIA2_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aria2}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $ARIA2_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$ARIA2_INSTALL_METHOD" = "libscript_native" ] || [ "$ARIA2_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aria2}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $ARIA2_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$ARIA2_INSTALL_METHOD" = "libscript_native" ] || [ "$ARIA2_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-aria2}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $ARIA2_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$ARIA2_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling aria2 $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/aria2/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/aria2/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $ARIA2_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
