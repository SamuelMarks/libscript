#!/bin/sh
# ## Overview
# Generic setup module for sbt.
# 
# ## Usage
# Execute this script to perform generic initialization steps for sbt.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

SBT_INSTALL_METHOD="$(libscript_resolve_install_method "SBT")"
ACTION="${ACTION:-install}"
VERSION="${SBT_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote sbt 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise ls sbt || true
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf list sbt || true
    elif [ "$SBT_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SBT_INSTALL_METHOD" = "vfox" ]; then
      vfox ls sbt || true
    elif [ "$SBT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote sbt || true
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf list all sbt || true
    elif [ "$SBT_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$SBT_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all sbt || true
    else
      if [ -n "${SBT_RELEASES_URL:-}" ]; then
        curl -sSL "${SBT_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/sbt" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise use "sbt@${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf global sbt "${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$SBT_INSTALL_METHOD" = "vfox" ]; then
      vfox use "sbt@${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "vfox" ]; then
      vfox use "sbt@${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "sbt" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "sbt ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "sbt" "default" "${EXACT_VERSION}"
      log_info "Set default sbt version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env sbt \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading sbt ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt..."
        libscript_depends "java"
        libscript_depends "bash"


      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt"
      if [ -n "${SBT_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SBT_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt/sbt-${VERSION}.tar.gz"
      else
        log_warn "SBT_DOWNLOAD_URL is not defined for sbt ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$SBT_INSTALL_METHOD" = "system" ]; then
      libscript_depends "sbt"
    elif [ "$SBT_INSTALL_METHOD" = "mise" ]; then
      mise install "sbt@${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "asdf" ]; then
      asdf install sbt "${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "sbt@${VERSION}"
    elif [ "$SBT_INSTALL_METHOD" = "vfox" ]; then
      vfox add sbt || true
      vfox install "sbt@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
         libscript_depends "curl"
         EXACT_VERSION=$(curl -sL https://api.github.com/repos/sbt/sbt/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
         if [ -z "${EXACT_VERSION}" ]; then EXACT_VERSION="latest"; fi
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing sbt ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends "java"
        libscript_depends "bash"


        mkdir -p "${TARGET_DIR}/bin"
        URL="https://github.com/sbt/sbt/releases/download/v${EXACT_VERSION}/sbt-${EXACT_VERSION}.tgz"
        TEMP_FILE=$(mktemp)
        libscript_depends "curl"
        libscript_depends "tar"
        curl -sSL "$URL" -o "$TEMP_FILE.tgz"
        tar -xzf "$TEMP_FILE.tgz" -C "${TARGET_DIR}" --strip-components=1
        rm -f "$TEMP_FILE.tgz"
      else
        log_info "sbt ${VERSION} is already installed."
      fi
      libscript_symlink_alias "sbt" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ] || [ "$SBT_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sbt}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $SBT_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ] || [ "$SBT_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sbt}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $SBT_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ] || [ "$SBT_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-sbt}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $SBT_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling sbt $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $SBT_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
