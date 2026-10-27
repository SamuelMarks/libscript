#!/bin/sh
# ## Overview
# Generic setup module for apk.
# 
# ## Usage
# Execute this script to perform generic initialization steps for apk.

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

APK_INSTALL_METHOD="$(libscript_resolve_install_method "APK")"
ACTION="${ACTION:-install}"
VERSION="${APK_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote apk 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION='3.0.7'
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi

  if [ -z "${APK_DOWNLOAD_URL:-}" ] && [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ]; then
    case "$ARCH" in
      x86_64|amd64) apk_arch="x86_64" ;;
      aarch64|arm64) apk_arch="aarch64" ;;
      armv7l|armhf) apk_arch="armv7" ;;
      x86|i686) apk_arch="x86" ;;
      *) apk_arch="" ;;
    esac
    if [ -n "$apk_arch" ]; then
      APK_DOWNLOAD_URL="https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v${EXACT_VERSION}/${apk_arch}/apk.static"
    fi
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "apk" "$ACTION" "$VERSION" "${APK_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${APK_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${APK_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://gitlab.alpinelinux.org/alpine/apk-tools" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "apk" "$ACTION" "$VERSION" "${APK_INSTALL_METHOD}"
    ;;
  download)
    if [ "$APK_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading apk ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/apk..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/apk"
      if [ -n "${APK_DOWNLOAD_URL:-}" ]; then
        libscript_download "${APK_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/apk/apk-${VERSION}.tar.gz"
      else
        log_warn "APK_DOWNLOAD_URL is not defined for apk ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$APK_INSTALL_METHOD" = "system" ]; then
      if command -v dnf >/dev/null 2>&1; then
        if ! command -v apk >/dev/null 2>&1; then
          _arch="${ARCH:-$(uname -m)}"
          case "$_arch" in
            arm64|aarch64) _apk_arch="aarch64" ;;
            x86_64|amd64) _apk_arch="x86_64" ;;
            armv7*) _apk_arch="armv7" ;;
            *) _apk_arch="$_arch" ;;
          esac
          _apk_tmp=$(mktemp)
          if libscript_download "https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.9/${_apk_arch}/apk.static" "${_apk_tmp}"; then
            priv cp "${_apk_tmp}" /usr/local/bin/apk 2>/dev/null || true
            priv chmod +x /usr/local/bin/apk 2>/dev/null || true
          fi
          rm -f "${_apk_tmp}"
        fi
      else
        libscript_depends 'apk'
      fi
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/apk/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing apk ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/apk/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/apk/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/apk" || true
              chmod +x "${TARGET_DIR}/bin/apk" || true
            fi
          fi
        else
          if [ -n "${APK_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${APK_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${APK_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${APK_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/apk" || true
              chmod +x "${TARGET_DIR}/bin/apk" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_error "No download URL provided for apk ${VERSION}."
            exit 1
          fi
        fi
      else
        log_info "apk ${VERSION} is already installed."
      fi
      libscript_symlink_alias "apk" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "apk" "$ACTION" "$VERSION" "${APK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
