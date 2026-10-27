#!/bin/sh
# ## Overview
# Generic setup module for cargo-binstall.
# 
# ## Usage
# Execute this script to perform generic initialization steps for cargo-binstall.

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

CARGO_BINSTALL_INSTALL_METHOD="$(libscript_resolve_install_method "CARGO_BINSTALL")"
ACTION="${ACTION:-install}"
VERSION="${CARGO_BINSTALL_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote cargo-binstall 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "cargo-binstall" "$ACTION" "$VERSION" "${CARGO_BINSTALL_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${CARGO_BINSTALL_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${CARGO_BINSTALL_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/rust-lang/cargo-binstall" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "cargo-binstall" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "cargo-binstall" "default" "${EXACT_VERSION}"
      
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends 'curl'
        EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "cargo-binstall ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "cargo-binstall" "default" "${EXACT_VERSION}"
      log_info "Set default cargo-binstall version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env cargo-binstall \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading cargo-binstall ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall"
      if [ -n "${CARGO_BINSTALL_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CARGO_BINSTALL_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cargo-binstall/cargo-binstall-${VERSION}.tar.gz"
      else
        log_warn "CARGO_BINSTALL_DOWNLOAD_URL is not defined for cargo-binstall ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$CARGO_BINSTALL_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'cargo-binstall'
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
        libscript_depends 'curl'
        EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cargo-binstall/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing cargo-binstall ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends 'curl' 'tar'
        mkdir -p "${TARGET_DIR}/bin"
        _os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        arch="$(uname -m)"
        if [ "$UNAME_LOWER" = "freebsd" ]; then
          log_info 'No native binary for FreeBSD. Falling back to system package manager for cargo-binstall...'
          libscript_depends 'cargo-binstall'
        elif [ -f /etc/alpine-release ]; then
          arch_musl="${arch}-unknown-linux-musl"
        else
          arch_musl="${arch}-unknown-linux-gnu"
        fi
        if [ "${EXACT_VERSION}" = "latest" ]; then
          EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/cargo-bins/cargo-binstall/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' | head -n 1)
        fi
        _cb_tar=$(mktemp)
        if libscript_download "https://github.com/cargo-bins/cargo-binstall/releases/download/v${EXACT_VERSION}/cargo-binstall-${arch_musl}.tgz" "${_cb_tar}"; then
          tar -xzf "${_cb_tar}" -C "${TARGET_DIR}/bin" || true
        fi
        rm -f "${_cb_tar}"
        chmod +x "${TARGET_DIR}/bin/cargo-binstall" || true
      else
        log_info "cargo-binstall ${VERSION} is already installed."
      fi
      libscript_symlink_alias "cargo-binstall" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "cargo-binstall" "$ACTION" "$VERSION" "${CARGO_BINSTALL_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
