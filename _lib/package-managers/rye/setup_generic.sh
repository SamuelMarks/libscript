#!/bin/sh
# ## Overview
# Generic setup module for rye.
# 
# ## Usage
# Execute this script to perform generic initialization steps for rye.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf "%s\n" "$d")}"
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

RYE_INSTALL_METHOD="$(libscript_resolve_install_method "RYE")"
ACTION="${ACTION:-install}"
VERSION="${RYE_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote rye 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "rye" "$ACTION" "$VERSION" "${RYE_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${RYE_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${RYE_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/wch/r-sourceye" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$RYE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "rye" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rye/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "rye ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "rye" "default" "${EXACT_VERSION}"
      log_info "Set default rye version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env rye \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$RYE_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading rye ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rye..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rye"
      if [ -n "${RYE_DOWNLOAD_URL:-}" ]; then
        libscript_download "${RYE_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rye/rye-${VERSION}.tar.gz"
      else
        log_warn "RYE_DOWNLOAD_URL is not defined for rye ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$RYE_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'rye'
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
         libscript_depends 'curl'
         EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/astral-sh/rye/releases/latest" | grep -oE "\"tag_name\": *\"[0-9.]+\"" | sed -E "s/.*\"([0-9.]+)\".*/\1/" | head -n 1)
         if [ -z "${EXACT_VERSION}" ]; then EXACT_VERSION="latest"; fi
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rye/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing rye ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        ARCH=$(uname -m)
        OS=$(uname -s | tr "[:upper:]" "[:lower:]")
        if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
        if [ "$OS" = "darwin" ]; then OS="macos"; elif [ "$OS" = "linux" ]; then OS="linux"; fi
        IS_MUSL=""
        if [ -f /etc/alpine-release ]; then IS_MUSL="-musl"; else IS_MUSL="-gnu"; fi
        URL="https://github.com/astral-sh/rye/releases/download/${EXACT_VERSION}/rye-${ARCH}-${OS}${IS_MUSL}.gz"
        TEMP_FILE=$(mktemp)
        libscript_depends 'curl'
        libscript_depends 'gzip'
        libscript_download "$URL" "$TEMP_FILE.gz"
        gzip -d "$TEMP_FILE.gz" || true
        cp "$TEMP_FILE" "${TARGET_DIR}/bin/rye"
        chmod +x "${TARGET_DIR}/bin/rye"
        rm -f "$TEMP_FILE"
      else
        log_info "rye ${VERSION} is already installed."
      fi
      libscript_symlink_alias "rye" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "rye" "$ACTION" "$VERSION" "${RYE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
