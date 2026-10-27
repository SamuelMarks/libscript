#!/bin/sh
# ## Overview
# Generic setup module for aqua.
# 
# ## Usage
# Execute this script to perform generic initialization steps for aqua.

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
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;; esac
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

AQUA_INSTALL_METHOD="$(libscript_resolve_install_method "AQUA")"
ACTION="${ACTION:-install}"
VERSION="${AQUA_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote aqua 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "aqua" "$ACTION" "$VERSION" "${AQUA_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${AQUA_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${AQUA_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/aquaproj/aqua" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "aqua" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "aqua" "default" "${EXACT_VERSION}"
      
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends 'curl'
        EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/aquaproj/aqua/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "aqua ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "aqua" "default" "${EXACT_VERSION}"
      log_info "Set default aqua version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env aqua \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$AQUA_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading aqua ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua"
      if [ -n "${AQUA_DOWNLOAD_URL:-}" ]; then
        libscript_download "${AQUA_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/aqua/aqua-${VERSION}.tar.gz"
      else
        log_warn "AQUA_DOWNLOAD_URL is not defined for aqua ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$AQUA_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'aqua'
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends 'curl'
        EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/aquaproj/aqua/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/aqua/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        libscript_depends 'curl' 'tar'
        log_info "Installing aqua ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        arch="$(uname -m)"
        case "${arch}" in
          'x86_64') arch='amd64' ;;
          'aarch64'|'arm64') arch='arm64' ;;
        esac
        libscript_fetch_stdout "https://github.com/aquaproj/aqua/releases/download/v${EXACT_VERSION}/aqua_${os}_${arch}.tar.gz" | tar -xzf - -C "${TARGET_DIR}/bin" || true
        chmod +x "${TARGET_DIR}/bin/aqua" || true
      else
        log_info "aqua ${VERSION} is already installed."
      fi
      libscript_symlink_alias "aqua" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "aqua" "$ACTION" "$VERSION" "${AQUA_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
