#!/bin/sh
# ## Overview
# Generic setup module for swift.
# 
# ## Usage
# Execute this script to perform generic initialization steps for swift.

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

SWIFT_INSTALL_METHOD="$(libscript_resolve_install_method "SWIFT")"
ACTION="${ACTION:-install}"
VERSION="${SWIFT_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote swift 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "swift" "$ACTION" "$VERSION" "${SWIFT_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${SWIFT_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${SWIFT_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/swiftlang/swift" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "swift" "$ACTION" "$VERSION" "${SWIFT_INSTALL_METHOD}"
    ;;
  download)
    if [ "$SWIFT_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading swift ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/swift..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/swift"
      if [ -n "${SWIFT_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SWIFT_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/swift/swift-${VERSION}.tar.gz"
      else
        log_warn "SWIFT_DOWNLOAD_URL is not defined for swift ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$SWIFT_INSTALL_METHOD" = "system" ]; then
      if command -v dnf >/dev/null 2>&1; then
        if ! command -v swift >/dev/null 2>&1; then
          if command -v crb >/dev/null 2>&1; then priv crb enable || true; fi
          libscript_depends swift-lang || true
        fi
      elif ! libscript_depends "swift"; then
        log_warn 'System package for swift failed. Falling back to native mock installation.'
        SWIFT_INSTALL_METHOD='libscript_native'
      fi
    fi

    # libscript_native implementation
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/swift/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing swift ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
        log_info 'Falling back to system package manager for swift...'
        libscript_depends 'swift'
      else
        log_error 'Native installation for swift from source is not supported yet.'
        exit 1
      fi
    else
      log_info "swift ${VERSION} is already installed."
    fi
    libscript_symlink_alias "swift" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "swift" "$ACTION" "$VERSION" "${SWIFT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
