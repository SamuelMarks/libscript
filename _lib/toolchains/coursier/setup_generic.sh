#!/bin/sh
# ## Overview
# Generic setup script for the coursier component.
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

COURSIER_INSTALL_METHOD="$(libscript_resolve_install_method "COURSIER")"
COURSIER_VERSION="${COURSIER_VERSION:-latest}"
ACTION="${ACTION:-install}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${COURSIER_VERSION}" = "latest" ] || [ "${COURSIER_VERSION}" = "lts" ]; then
    libscript_depends "curl"

    EXACT_VERSION=$(curl -sL https://api.github.com/repos/coursier/coursier/releases/latest | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4 | sed 's/^v//')
    if [ -z "$EXACT_VERSION" ]; then
      EXACT_VERSION="latest"
    fi
  else
    EXACT_VERSION="${COURSIER_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${COURSIER_INSTALL_METHOD}" = "mise" ]; then
      mise ls coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "asdf" ]; then
      asdf list coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${COURSIER_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "system" ]; then
      coursier --version || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "${COURSIER_INSTALL_METHOD}" = "mise" ]; then
      mise ls-remote coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "asdf" ]; then
      asdf list all coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "${COURSIER_INSTALL_METHOD}" = "vfox" ]; then
      vfox ls all coursier
    elif [ "${COURSIER_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      printf '%s\n' "Fetching remote versions not implemented generically for coursier"
    fi
    exit 0
    ;;
  use)
    if [ "${COURSIER_INSTALL_METHOD}" = "mise" ]; then
      mise use "coursier@${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "asdf" ]; then
      asdf global coursier "${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "${COURSIER_INSTALL_METHOD}" = "vfox" ]; then
      vfox use "coursier@${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "coursier" "${COURSIER_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "coursier" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "coursier ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "coursier" "default" "${EXACT_VERSION}"
      log_info "Set default coursier version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env coursier \"${COURSIER_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$COURSIER_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading coursier ${VERSION:-} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/coursier..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/coursier"
      if [ -n "${COURSIER_DOWNLOAD_URL:-}" ]; then
        libscript_download "${COURSIER_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/coursier/coursier-${VERSION:-}.tar.gz"
      else
        log_warn "COURSIER_DOWNLOAD_URL is not defined for coursier ${VERSION:-}."
      fi
    fi
    exit 0
    ;;
  install)

    if [ "${COURSIER_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'coursier'
    elif [ "${COURSIER_INSTALL_METHOD}" = "mise" ]; then
      mise install "coursier@${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "asdf" ]; then
      asdf install coursier "${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "pkgx" ]; then
      pkgx install "coursier@${COURSIER_VERSION}"
    elif [ "${COURSIER_INSTALL_METHOD}" = "vfox" ]; then
      vfox add coursier || true
      vfox install "coursier@${COURSIER_VERSION}"
    else
        # libscript_native implementation
        if [ -f /etc/alpine-release ]; then
          log_info "coursier binaries are built for glibc. Skipping native install on Alpine."
          exit 0
        fi

        resolve_exact_version
        if [ "${EXACT_VERSION}" = "latest" ]; then
           libscript_depends "curl"
    libscript_depends "curl"

           EXACT_VERSION=$(curl -sL https://api.github.com/repos/coursier/coursier/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
        fi
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/${EXACT_VERSION}"
        if [ ! -d "${TARGET_DIR}" ]; then
          log_info "Installing coursier ${VERSION} natively to ${TARGET_DIR}..."
          mkdir -p "${TARGET_DIR}/bin"
          URL="https://github.com/coursier/coursier/releases/download/v${EXACT_VERSION}/cs-x86_64-pc-linux.gz"
          TEMP_FILE=$(mktemp)
          libscript_depends "curl"
          libscript_depends "gzip"
          libscript_depends "java"
          curl -sSL "$URL" -o "$TEMP_FILE.gz"
          gzip -d "$TEMP_FILE.gz" || true
          cp "$TEMP_FILE" "${TARGET_DIR}/bin/coursier"
          chmod +x "${TARGET_DIR}/bin/coursier"
          rm -f "$TEMP_FILE"
        else
          log_info "coursier ${VERSION} is already installed."
        fi
        libscript_symlink_alias "coursier" "$VERSION" "${EXACT_VERSION}"
        fi

    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$COURSIER_INSTALL_METHOD" = "libscript_native" ] || [ "$COURSIER_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-coursier}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $COURSIER_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$COURSIER_INSTALL_METHOD" = "libscript_native" ] || [ "$COURSIER_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-coursier}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $COURSIER_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$COURSIER_INSTALL_METHOD" = "libscript_native" ] || [ "$COURSIER_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-coursier}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $COURSIER_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$COURSIER_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling coursier $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/coursier/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $COURSIER_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
