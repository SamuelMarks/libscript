#!/bin/sh
# ## Overview
# Generic setup module for stack.
# 
# ## Usage
# Execute this script to perform generic initialization steps for stack.

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

STACK_INSTALL_METHOD="$(libscript_resolve_install_method "STACK")"
ACTION="${ACTION:-install}"
VERSION="${STACK_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote stack 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "stack" "$ACTION" "$VERSION" "${STACK_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${STACK_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${STACK_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/commercialhaskell/stack" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "stack" "$ACTION" "$VERSION" "${STACK_INSTALL_METHOD}"
    ;;
  download)
    if [ "$STACK_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading stack ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/stack..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/stack"
      if [ -n "${STACK_DOWNLOAD_URL:-}" ]; then
        libscript_download "${STACK_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/stack/stack-${VERSION}.tar.gz"
      else
        log_warn "STACK_DOWNLOAD_URL is not defined for stack ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$STACK_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'stack'
    else
      # libscript_native implementation
      if [ -f /etc/alpine-release ] && [ "$(uname -m)" != "x86_64" ]; then
        log_info 'stack binary on Alpine is only available for x86_64. Skipping.'
        exit 0
      fi

      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/stack/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing stack ${VERSION} natively to ${TARGET_DIR}..."
        if [ "$UNAME_LOWER" = "freebsd" ]; then
          log_info 'No native binary for FreeBSD. Falling back to system package manager for stack...'
          libscript_depends 'stack'
          if command -v "stack" >/dev/null 2>&1; then
            mkdir -p "${TARGET_DIR}/bin"
            ln -sf "$(command -v "stack")" "${TARGET_DIR}/bin/stack"
          fi
        else
          libscript_depends 'curl'
          mkdir -p "${TARGET_DIR}/bin"
          libscript_fetch_stdout https://get.haskellstack.org/ | sh -s - -d "${TARGET_DIR}/bin"
        fi
      else
        log_info "stack ${VERSION} is already installed."
      fi
      libscript_symlink_alias "stack" "$VERSION" "${EXACT_VERSION}"

    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "stack" "$ACTION" "$VERSION" "${STACK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
