#!/bin/sh
# ## Overview
# Generic setup module for minio.
# 
# ## Usage
# Execute this script to perform generic initialization steps for minio.

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

MINIO_INSTALL_METHOD="$(libscript_resolve_install_method "MINIO")"
ACTION="${ACTION:-install}"
VERSION="${MINIO_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote minio 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "minio" "$ACTION" "$VERSION" "${MINIO_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${MINIO_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${MINIO_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/minio/minio" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$MINIO_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "minio" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/minio/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "minio ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "minio" "default" "${EXACT_VERSION}"
      log_info "Set default minio version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env minio \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$MINIO_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading minio ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/minio..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/minio"
      if [ -n "${MINIO_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MINIO_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/minio/minio-${VERSION}.tar.gz"
      else
        log_warn "MINIO_DOWNLOAD_URL is not defined for minio ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$MINIO_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'minio'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/minio/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing minio ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        ARCH=$(uname -m)
        OS=$(uname -s | tr "[:upper:]" "[:lower:]")
        if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="arm64"; fi
        URL="https://dl.min.io/aistor/minio/release/${OS}-${ARCH}/minio"
        TEMP_FILE=$(mktemp)
        libscript_depends 'curl'
        if ! libscript_download "$URL" "$TEMP_FILE"; then
          log_error "Failed to download minio from $URL"
          rm -f "$TEMP_FILE"
          exit 1
        fi
        cp "$TEMP_FILE" "${TARGET_DIR}/bin/minio"
        chmod +x "${TARGET_DIR}/bin/minio"
        rm -f "$TEMP_FILE"
      else
        log_info "minio ${VERSION} is already installed."
      fi
      libscript_symlink_alias "minio" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "minio" "default" "${EXACT_VERSION}"
      if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "minio" ]; then
        libscript_symlink_alias "minio" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "minio" "$ACTION" "$VERSION" "${MINIO_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
