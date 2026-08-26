#!/bin/sh
# ## Overview
# Generic setup module for gcsfuse.
# 
# ## Usage
# Execute this script to perform generic initialization steps for gcsfuse.

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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
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

GCSFUSE_INSTALL_METHOD="$(libscript_resolve_install_method "GCSFUSE")"
ACTION="${ACTION:-install}"
VERSION="${GCSFUSE_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote gcsfuse 2>/dev/null | tail -n 1)
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
    if [ "$GCSFUSE_INSTALL_METHOD" = "mise" ]; then
      mise ls gcsfuse || true
    elif [ "$GCSFUSE_INSTALL_METHOD" = "asdf" ]; then
      asdf list gcsfuse || true
    elif [ "$GCSFUSE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "vfox" ]; then
      vfox ls gcsfuse || true
    elif [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$GCSFUSE_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote gcsfuse || true
    elif [ "$GCSFUSE_INSTALL_METHOD" = "asdf" ]; then
      asdf list all gcsfuse || true
    elif [ "$GCSFUSE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all gcsfuse || true
    else
      if [ -n "${GCSFUSE_RELEASES_URL:-}" ]; then
        curl -sSL "${GCSFUSE_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/gcsfuse" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$GCSFUSE_INSTALL_METHOD" = "mise" ]; then
      mise use "gcsfuse@${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "asdf" ]; then
      asdf global gcsfuse "${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "vfox" ]; then
      vfox use "gcsfuse@${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "vfox" ]; then
      vfox use "gcsfuse@${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "gcsfuse" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "gcsfuse ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "gcsfuse" "default" "${EXACT_VERSION}"
      log_info "Set default gcsfuse version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env gcsfuse \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$GCSFUSE_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading gcsfuse ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcsfuse..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcsfuse"
      if [ -n "${GCSFUSE_DOWNLOAD_URL:-}" ]; then
        libscript_download "${GCSFUSE_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcsfuse/gcsfuse-${VERSION}.tar.gz"
      else
        log_warn "GCSFUSE_DOWNLOAD_URL is not defined for gcsfuse ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      libscript_depends "gcsfuse"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "mise" ]; then
      mise install "gcsfuse@${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "asdf" ]; then
      asdf install gcsfuse "${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "gcsfuse@${VERSION}"
    elif [ "$GCSFUSE_INSTALL_METHOD" = "vfox" ]; then
      vfox add gcsfuse || true
      vfox install "gcsfuse@${VERSION}"
    else
      # libscript_native implementation
        if [ -f /etc/alpine-release ]; then
          log_info "gcsfuse official binaries are deb/rpm and require glibc. Skipping on Alpine."
          exit 0
        fi

      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing gcsfuse ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends "curl"
        if [ "${EXACT_VERSION}" = "latest" ]; then
           EXACT_VERSION=$(curl -sL https://api.github.com/repos/GoogleCloudPlatform/gcsfuse/releases/latest | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
        fi
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/${EXACT_VERSION}"
        if [ ! -d "${TARGET_DIR}" ]; then
           mkdir -p "${TARGET_DIR}/bin"
           ARCH=$(uname -m)
           OS=$(uname -s | tr "[:upper:]" "[:lower:]")
           if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
           TEMP_FILE=$(mktemp)
           libscript_depends "curl"
           if [ "$OS" = "linux" ]; then
             URL="https://github.com/GoogleCloudPlatform/gcsfuse/releases/download/v${EXACT_VERSION}/gcsfuse_${EXACT_VERSION}_${ARCH}.deb"
             if ! curl -sSLf "$URL" -o "$TEMP_FILE.deb"; then
                log_error "Failed to download gcsfuse from $URL"
                rm -f "$TEMP_FILE.deb"
                exit 1
             fi
             libscript_depends "binutils" "tar" "xz-utils" || true
             TEMP_EXTRACT=$(mktemp -d)
             (cd "$TEMP_EXTRACT" && ar x "$TEMP_FILE.deb" && tar -xf data.tar.*)
             cp "$TEMP_EXTRACT/usr/bin/gcsfuse" "${TARGET_DIR}/bin/gcsfuse" || true
             rm -rf "$TEMP_EXTRACT"
             rm -f "$TEMP_FILE.deb"
           else
             log_error "gcsfuse native installation only supports Linux currently."
             exit 1
           fi
           chmod +x "${TARGET_DIR}/bin/gcsfuse" || true
        fi
      else
        log_info "gcsfuse ${VERSION} is already installed."
      fi
      libscript_symlink_alias "gcsfuse" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$GCSFUSE_INSTALL_METHOD" = "libscript_native" ] || [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcsfuse}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $GCSFUSE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$GCSFUSE_INSTALL_METHOD" = "libscript_native" ] || [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcsfuse}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $GCSFUSE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$GCSFUSE_INSTALL_METHOD" = "libscript_native" ] || [ "$GCSFUSE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcsfuse}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $GCSFUSE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$GCSFUSE_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling gcsfuse $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcsfuse/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $GCSFUSE_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
