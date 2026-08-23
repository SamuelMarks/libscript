#!/bin/sh
# ## Overview
# Generic setup script for the just component.
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

JUST_INSTALL_METHOD="$(libscript_resolve_install_method "JUST")"
JUST_VERSION="${JUST_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${JUST_VERSION}" = "latest" ] || [ "${JUST_VERSION}" = "lts" ]; then
    libscript_depends "curl"

    EXACT_VERSION=$(curl -sL https://api.github.com/repos/casey/just/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${JUST_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${JUST_INSTALL_METHOD}" = "mise" ]; then
      mise ls just
    elif [ "${JUST_INSTALL_METHOD}" = "asdf" ]; then
      asdf list just
    elif [ "${JUST_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${JUST_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls just
    elif [ "${JUST_INSTALL_METHOD}" = "system" ]; then
      just --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/just/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${JUST_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote just
    elif [ "${JUST_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all just
    elif [ "${JUST_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${JUST_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all just
    elif [ "${JUST_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for just"
    fi
    exit 0
    ;;
  use)
    if [ "${JUST_INSTALL_METHOD}" = "mise" ]; then
      mise use "just@${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "asdf" ]; then
      asdf global just "${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${JUST_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "just@${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "just" "${JUST_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "just" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/just/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "just ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "just" "default" "${EXACT_VERSION}"
      log_info "Set default just version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env just \"${JUST_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$JUST_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading just ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/just..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/just"
      if [ -n "${JUST_DOWNLOAD_URL:-}" ]; then
        libscript_download "${JUST_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/just/just-${VERSION:-}.tar.gz"
      else
        log_warn "JUST_DOWNLOAD_URL is not defined for just ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${JUST_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'just'
    elif [ "${JUST_INSTALL_METHOD}" = "mise" ]; then
      mise install "just@${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "asdf" ]; then
      asdf install just "${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "just@${JUST_VERSION}"
    elif [ "${JUST_INSTALL_METHOD}" = "vfox" ]; then
      vfox add just || true
      vfox install "just@${JUST_VERSION}"
    else
        # libscript_native implementation
        resolve_exact_version
        if [ "${EXACT_VERSION}" = "latest" ]; then
           libscript_depends "curl"
    libscript_depends "curl"

           EXACT_VERSION=$(curl -sL https://api.github.com/repos/casey/just/releases/latest | grep -oE "\"tag_name\": *\"[0-9.]+\"" | sed -E "s/.*\"([0-9.]+)\".*/\1/" | head -n 1)
        fi
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/just/${EXACT_VERSION}"
        if [ ! -d "${TARGET_DIR}" ]; then
          log_info "Installing just ${VERSION} natively to ${TARGET_DIR}..."
          mkdir -p "${TARGET_DIR}/bin"
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
          IS_MUSL=""
          if [ -f /etc/alpine-release ]; then IS_MUSL="-musl"; fi
          URL="https://github.com/casey/just/releases/download/${EXACT_VERSION}/just-${EXACT_VERSION}-${ARCH}-unknown-linux${IS_MUSL}.tar.gz"
          TEMP_FILE=$(mktemp)
          libscript_depends "curl"
          libscript_depends "tar"
          curl -sSL "$URL" -o "$TEMP_FILE.tar.gz"
          tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}/bin" "just" || cp "$TEMP_FILE.tar.gz" "${TARGET_DIR}/bin/just"
          chmod +x "${TARGET_DIR}/bin/just"
          rm -f "$TEMP_FILE.tar.gz"
        else
          log_info "just ${VERSION} is already installed."
        fi
        libscript_symlink_alias "just" "$VERSION" "${EXACT_VERSION}"
        fi

    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$JUST_INSTALL_METHOD" = "libscript_native" ] || [ "$JUST_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-just}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $JUST_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$JUST_INSTALL_METHOD" = "libscript_native" ] || [ "$JUST_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-just}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $JUST_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$JUST_INSTALL_METHOD" = "libscript_native" ] || [ "$JUST_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-just}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $JUST_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$JUST_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling just $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/just/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/just/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $JUST_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
