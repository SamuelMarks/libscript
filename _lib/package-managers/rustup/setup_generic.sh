#!/bin/sh
# ## Overview
# Generic setup module for rustup.
# 
# ## Usage
# Execute this script to perform generic initialization steps for rustup.

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

RUSTUP_INSTALL_METHOD="$(libscript_resolve_install_method "RUSTUP")"
ACTION="${ACTION:-install}"
VERSION="${RUSTUP_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote rustup 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "rustup" "$ACTION" "$VERSION" "${RUSTUP_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${RUSTUP_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${RUSTUP_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/wch/r-sourceustup" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "rustup" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "rustup ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "rustup" "default" "${EXACT_VERSION}"
      log_info "Set default rustup version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env rustup \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$RUSTUP_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading rustup ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup"
      if [ -n "${RUSTUP_DOWNLOAD_URL:-}" ]; then
        libscript_download "${RUSTUP_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rustup/rustup-${VERSION}.tar.gz"
      else
        log_warn "RUSTUP_DOWNLOAD_URL is not defined for rustup ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$RUSTUP_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "rustup"; then
        log_info 'System package manager does not have rustup. Falling back to native...'
        RUSTUP_INSTALL_METHOD='libscript_native'
      fi
    fi
    # libscript_native implementation
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/rustup/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing rustup ${VERSION} natively to ${TARGET_DIR}..."
      if [ "$UNAME_LOWER" = "freebsd" ] || [ "$UNAME_LOWER" = "sunos" ]; then
        log_info "No native binary for $UNAME_LOWER. Falling back to system package manager for rustup..."
        libscript_depends 'rust'
        mkdir -p "${TARGET_DIR}/.cargo/bin"
        _rustc_bin=$(command -v "rustc" 2>/dev/null || echo "/usr/local/bin/rustc")
        _cargo_bin=$(command -v "cargo" 2>/dev/null || echo "/usr/local/bin/cargo")
        ln -sf "$_rustc_bin" "${TARGET_DIR}/.cargo/bin/rustc" || true
        ln -sf "$_cargo_bin" "${TARGET_DIR}/.cargo/bin/cargo" || true
      else
        libscript_depends 'curl'
        if [ -f /etc/alpine-release ]; then
          libscript_depends 'libgcc'
        fi
        mkdir -p "${TARGET_DIR}"
        export RUSTUP_HOME="${TARGET_DIR}/.rustup"
        export CARGO_HOME="${TARGET_DIR}/.cargo"
        unset RUSTUP_VERSION

        libscript_fetch_stdout "https://sh.rustup.rs" | sh -s -- -y --no-modify-path
      fi
    else
      log_info "rustup ${VERSION} is already installed."
    fi
    libscript_symlink_alias "rustup" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "rustup" "$ACTION" "$VERSION" "${RUSTUP_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
