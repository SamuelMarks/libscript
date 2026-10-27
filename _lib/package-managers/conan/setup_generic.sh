#!/bin/sh
# ## Overview
# Generic setup module for conan.
# 
# ## Usage
# Execute this script to perform generic initialization steps for conan.

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

CONAN_INSTALL_METHOD="$(libscript_resolve_install_method "CONAN")"
ACTION="${ACTION:-install}"
VERSION="${CONAN_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote conan 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "conan" "$ACTION" "$VERSION" "${CONAN_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${CONAN_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${CONAN_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/conan-io/conan" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "conan" "$ACTION" "$VERSION" "${CONAN_INSTALL_METHOD}"
    ;;
  download)
    if [ "$CONAN_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading conan ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan"
      if [ -n "${CONAN_DOWNLOAD_URL:-}" ]; then
        libscript_download "${CONAN_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/conan/conan-${VERSION}.tar.gz"
      else
        log_warn "CONAN_DOWNLOAD_URL is not defined for conan ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$CONAN_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'conan'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/conan/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing conan ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends 'python' 'python3-venv' || true
        if ! type libscript_python_venv >/dev/null 2>&1; then
          . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
        fi
        libscript_python_venv "${TARGET_DIR}/venv"
        if [ "$UNAME_LOWER" = "freebsd" ]; then
          libscript_depends 'gcc' 'make' 'python3'
        elif [ -f /etc/alpine-release ]; then
          libscript_depends 'gcc' 'musl-dev' 'python3-dev' 'libffi-dev' 'openssl-dev' 'make'
        fi
        "${TARGET_DIR}/venv/bin/pip" install conan
        mkdir -p "${TARGET_DIR}/bin"
        ln -sf "${TARGET_DIR}/venv/bin/conan" "${TARGET_DIR}/bin/conan"
      else
        log_info "conan ${VERSION} is already installed."
      fi
      libscript_symlink_alias "conan" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "conan" "$ACTION" "$VERSION" "${CONAN_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
