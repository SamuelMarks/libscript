#!/bin/sh
# ## Overview
# Generic setup module for cc.
# 
# ## Usage
# Execute this script to perform generic initialization steps for cc.

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

CC_INSTALL_METHOD="$(libscript_resolve_install_method "CC")"
ACTION="${ACTION:-install}"
VERSION="${CC_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote cc 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "cc" "$ACTION" "$VERSION" "${CC_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${CC_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${CC_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/gcc-mirror/gcc" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "cc" "$ACTION" "$VERSION" "${CC_INSTALL_METHOD}"
    ;;
  download)
    if [ "$CC_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading cc ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc"
      if [ -n "${CC_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CC_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/cc-${VERSION}.tar.gz"
      else
        printf '%s\n' 'CC_DOWNLOAD_URL is not defined. Skipping.'
      fi
    fi
    exit 0
    ;;
  install)
    _backend="${CC_BACKEND:-${CC_BUILD_TOOLCHAIN:-default}}"
    if [ "${_backend}" != "default" ] && [ -d "${LIBSCRIPT_ROOT_DIR}/_lib/languages/${_backend}" ]; then
      unset SCRIPT_NAME || true
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_backend}" "${VERSION}"
      exit 0
    fi
    if [ "$CC_INSTALL_METHOD" = "system" ]; then
      if command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; then
        log_info 'Host C compiler already available.'
      else
        libscript_depends 'gcc'
      fi
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/cc/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing cc ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/cc/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/cc" || true
              chmod +x "${TARGET_DIR}/bin/cc" || true
            fi
          fi
        else
          if [ -n "${CC_DOWNLOAD_URL:-}" ]; then
            libscript_fetch_stdout "${CC_DOWNLOAD_URL}" | tar -xzf - -C "${TARGET_DIR}" --strip-components=1 || true
          else
            log_error "No download URL provided for cc ${VERSION}."
            exit 1
          fi
        fi
      else
        log_info "cc ${VERSION} is already installed."
      fi
      libscript_symlink_alias "cc" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "cc" "$ACTION" "$VERSION" "${CC_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
