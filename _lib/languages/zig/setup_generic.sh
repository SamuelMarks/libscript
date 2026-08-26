#!/bin/sh
# ## Overview
# Generic setup module for zig.
# 
# ## Usage
# Execute this script to perform generic initialization steps for zig.

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

ZIG_INSTALL_METHOD="system"
ACTION="${ACTION:-install}"
VERSION="${ZIG_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote zig 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ] && [ "$_latest" != "Fetching remote versions not implemented generically for zig" ]; then
      EXACT_VERSION="$_latest"
    else
      libscript_depends "curl" "jq" || true
      EXACT_VERSION=$(curl -sL https://ziglang.org/download/index.json | jq -r 'keys | map(select(. != "master")) | sort | last')
      if [ -z "$EXACT_VERSION" ] || [ "$EXACT_VERSION" = "null" ]; then
         EXACT_VERSION="0.13.0"
      fi
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise ls zig || true
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf list zig || true
    elif [ "$ZIG_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$ZIG_INSTALL_METHOD" = "vfox" ]; then
      vfox ls zig || true
    elif [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote zig || true
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf list all zig || true
    elif [ "$ZIG_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$ZIG_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all zig || true
    else
      if [ -n "${ZIG_RELEASES_URL:-}" ]; then
        curl -sSL "${ZIG_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/libscript/zig" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise use "zig@${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf global zig "${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$ZIG_INSTALL_METHOD" = "vfox" ]; then
      vfox use "zig@${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "vfox" ]; then
      vfox use "zig@${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "zig" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "zig" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "zig ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "zig" "default" "${EXACT_VERSION}"
      log_info "Set default zig version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env zig \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$ZIG_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading zig ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zig..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zig"
      if [ -n "${ZIG_DOWNLOAD_URL:-}" ]; then
        libscript_download "${ZIG_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zig/zig-${VERSION}.tar.gz"
      else
        log_warn "ZIG_DOWNLOAD_URL is not defined for zig ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      libscript_depends "zig"
    elif [ "$ZIG_INSTALL_METHOD" = "mise" ]; then
      mise install "zig@${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "asdf" ]; then
      asdf install zig "${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "zig@${VERSION}"
    elif [ "$ZIG_INSTALL_METHOD" = "vfox" ]; then
      vfox add zig || true
      vfox install "zig@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing zig ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zig/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zig/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/zig" || true
              chmod +x "${TARGET_DIR}/bin/zig" || true
            fi
          fi
        else
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
          OS=$(uname -s | tr "[:upper:]" "[:lower:]")
          if [ "$OS" = "darwin" ]; then OS="macos"; elif [ "$OS" = "linux" ]; then OS="linux"; fi
          URL="https://ziglang.org/download/${EXACT_VERSION}/zig-${OS}-${ARCH}-${EXACT_VERSION}.tar.xz"
          TEMP_FILE=$(mktemp)
          libscript_depends "curl" "tar" "xz" || true
          if ! curl -sSLf "$URL" -o "$TEMP_FILE.tar.xz"; then
            log_error "Failed to download zig from $URL"
            rm -f "$TEMP_FILE.tar.xz"
            exit 1
          fi
          tar -xf "$TEMP_FILE.tar.xz" -C "${TARGET_DIR}" --strip-components=1 || true
          rm -f "$TEMP_FILE.tar.xz"
        fi
      else
        log_info "zig ${VERSION} is already installed."
      fi
      libscript_symlink_alias "zig" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$ZIG_INSTALL_METHOD" = "libscript_native" ] || [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-zig}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $ZIG_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$ZIG_INSTALL_METHOD" = "libscript_native" ] || [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-zig}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $ZIG_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$ZIG_INSTALL_METHOD" = "libscript_native" ] || [ "$ZIG_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-zig}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $ZIG_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$ZIG_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling zig $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/zig/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $ZIG_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
