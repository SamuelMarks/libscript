#!/bin/sh
# ## Overview
# Generic setup script for the wait4x component.
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

WAIT4X_INSTALL_METHOD="${WAIT4X_INSTALL_METHOD:-libscript_native}"
WAIT4X_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$WAIT4X_INSTALL_METHOD" libscript_resolve_install_method "WAIT4X")"
WAIT4X_VERSION="${WAIT4X_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${WAIT4X_VERSION}" = "latest" ] || [ "${WAIT4X_VERSION}" = "lts" ]; then
    libscript_depends "curl"

    EXACT_VERSION=$(curl -sL https://api.github.com/repos/atkrad/wait4x/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${WAIT4X_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${WAIT4X_INSTALL_METHOD}" = "mise" ]; then
      mise ls wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "asdf" ]; then
      asdf list wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "system" ]; then
      wait4x --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${WAIT4X_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all wait4x
    elif [ "${WAIT4X_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for wait4x"
    fi
    exit 0
    ;;
  use)
    if [ "${WAIT4X_INSTALL_METHOD}" = "mise" ]; then
      mise use "wait4x@${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "asdf" ]; then
      asdf global wait4x "${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "wait4x@${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "wait4x" "${WAIT4X_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "wait4x" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "wait4x ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "wait4x" "default" "${EXACT_VERSION}"
      log_info "Set default wait4x version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env wait4x \"${WAIT4X_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$WAIT4X_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading wait4x ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wait4x..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wait4x"
      if [ -n "${WAIT4X_DOWNLOAD_URL:-}" ]; then
        libscript_download "${WAIT4X_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wait4x/wait4x-${VERSION:-}.tar.gz"
      else
        log_warn "WAIT4X_DOWNLOAD_URL is not defined for wait4x ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${WAIT4X_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'wait4x'
    elif [ "${WAIT4X_INSTALL_METHOD}" = "mise" ]; then
      mise install "wait4x@${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "asdf" ]; then
      asdf install wait4x "${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "wait4x@${WAIT4X_VERSION}"
    elif [ "${WAIT4X_INSTALL_METHOD}" = "vfox" ]; then
      vfox add wait4x || true
      vfox install "wait4x@${WAIT4X_VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing wait4x ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        ARCH=$(uname -m)
        OS=$(uname -s | tr "[:upper:]" "[:lower:]")
        if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
        URL="https://github.com/wait4x/wait4x/releases/download/v${EXACT_VERSION}/wait4x-${OS}-${ARCH}.tar.gz"
        TEMP_FILE=$(mktemp)
        libscript_depends "curl"
        libscript_depends "tar"
        curl -sSL "$URL" -o "$TEMP_FILE.tar.gz"
        tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}/bin" "wait4x" || cp "$TEMP_FILE.tar.gz" "${TARGET_DIR}/bin/wait4x"
        chmod +x "${TARGET_DIR}/bin/wait4x"
        rm -f "$TEMP_FILE.tar.gz"
      else
        log_info "wait4x ${VERSION} is already installed."
      fi
      libscript_symlink_alias "wait4x" "$VERSION" "${EXACT_VERSION}"
        fi

    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$WAIT4X_INSTALL_METHOD" = "libscript_native" ] || [ "$WAIT4X_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wait4x}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $WAIT4X_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$WAIT4X_INSTALL_METHOD" = "libscript_native" ] || [ "$WAIT4X_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wait4x}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $WAIT4X_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$WAIT4X_INSTALL_METHOD" = "libscript_native" ] || [ "$WAIT4X_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-wait4x}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $WAIT4X_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$WAIT4X_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling wait4x $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/wait4x/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $WAIT4X_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
