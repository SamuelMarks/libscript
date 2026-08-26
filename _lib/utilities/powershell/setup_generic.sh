#!/bin/sh
# ## Overview
# Generic setup script for the powershell component.
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

POWERSHELL_INSTALL_METHOD="${POWERSHELL_INSTALL_METHOD:-system}"
POWERSHELL_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$POWERSHELL_INSTALL_METHOD" libscript_resolve_install_method "POWERSHELL")"
POWERSHELL_VERSION="${POWERSHELL_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${POWERSHELL_VERSION}" = "latest" ] || [ "${POWERSHELL_VERSION}" = "lts" ]; then
    libscript_depends "curl"

    EXACT_VERSION=$(curl -sL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${POWERSHELL_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${POWERSHELL_INSTALL_METHOD}" = "mise" ]; then
      mise ls powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "asdf" ]; then
      asdf list powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "system" ]; then
      powershell --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/powershell/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${POWERSHELL_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all powershell
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for powershell"
    fi
    exit 0
    ;;
  use)
    if [ "${POWERSHELL_INSTALL_METHOD}" = "mise" ]; then
      mise use "powershell@${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "asdf" ]; then
      asdf global powershell "${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "powershell@${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "powershell" "${POWERSHELL_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "powershell" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/powershell/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "powershell ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "powershell" "default" "${EXACT_VERSION}"
      log_info "Set default powershell version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env powershell \"${POWERSHELL_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$POWERSHELL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading powershell ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/powershell..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/powershell"
      if [ -n "${POWERSHELL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${POWERSHELL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/powershell/powershell-${VERSION:-}.tar.gz"
      else
        log_warn "POWERSHELL_DOWNLOAD_URL is not defined for powershell ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${POWERSHELL_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'powershell'
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "mise" ]; then
      mise install "powershell@${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "asdf" ]; then
      asdf install powershell "${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "powershell@${POWERSHELL_VERSION}"
    elif [ "${POWERSHELL_INSTALL_METHOD}" = "vfox" ]; then
      vfox add powershell || true
      vfox install "powershell@${POWERSHELL_VERSION}"
    else
        # libscript_native implementation
        resolve_exact_version
        if [ "${EXACT_VERSION}" = "latest" ]; then
           libscript_depends "curl"
    libscript_depends "curl"

           EXACT_VERSION=$(curl -sL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
        fi
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/powershell/${EXACT_VERSION}"
        if [ ! -d "${TARGET_DIR}" ]; then
          log_info "Installing powershell ${VERSION} natively to ${TARGET_DIR}..."
          mkdir -p "${TARGET_DIR}/bin"
          ARCH=$(uname -m)
          OS=$(uname -s | tr "[:upper:]" "[:lower:]")
          if [ "$ARCH" = "x86_64" ]; then ARCH="x64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
          if [ "$OS" = "darwin" ]; then OS="osx"; fi
          URL="https://github.com/PowerShell/PowerShell/releases/download/v${EXACT_VERSION}/powershell-${EXACT_VERSION}-${OS}-${ARCH}.tar.gz"
          TEMP_FILE=$(mktemp)
          libscript_depends "curl" "tar"
          if [ "$OS" = "linux" ]; then libscript_depends "libicu" || true; fi
          if ! curl -sSLf "$URL" -o "$TEMP_FILE.tar.gz"; then
            log_error "Failed to download powershell from $URL"
            rm -f "$TEMP_FILE.tar.gz"
            exit 1
          fi
          tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}" || true
          ln -sf "${TARGET_DIR}/pwsh" "${TARGET_DIR}/bin/pwsh"
          chmod +x "${TARGET_DIR}/pwsh" || true
          rm -f "$TEMP_FILE.tar.gz"
        else
          log_info "powershell ${VERSION} is already installed."
        fi
        libscript_symlink_alias "powershell" "$VERSION" "${EXACT_VERSION}"
        fi

    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$POWERSHELL_INSTALL_METHOD" = "libscript_native" ] || [ "$POWERSHELL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-powershell}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $POWERSHELL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$POWERSHELL_INSTALL_METHOD" = "libscript_native" ] || [ "$POWERSHELL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-powershell}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $POWERSHELL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$POWERSHELL_INSTALL_METHOD" = "libscript_native" ] || [ "$POWERSHELL_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-powershell}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $POWERSHELL_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$POWERSHELL_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling powershell $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/powershell/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/powershell/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $POWERSHELL_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
