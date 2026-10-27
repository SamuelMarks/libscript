#!/bin/sh
# ## Overview
# Generic setup module for yay.
# 
# ## Usage
# Execute this script to perform generic initialization steps for yay.

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

YAY_INSTALL_METHOD="$(libscript_resolve_install_method "YAY")"
ACTION="${ACTION:-install}"
VERSION="${YAY_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote yay 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/Jguer/yay/releases/latest" | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "yay" "$ACTION" "$VERSION" "${YAY_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${YAY_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${YAY_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/Jguer/yay" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "yay" "$ACTION" "$VERSION" "${YAY_INSTALL_METHOD}"
    ;;
  download)
    if [ "$YAY_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading yay ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yay..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yay"
      if [ -n "${YAY_DOWNLOAD_URL:-}" ]; then
        libscript_download "${YAY_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yay/yay-${VERSION}.tar.gz"
      else
        log_warn "YAY_DOWNLOAD_URL is not defined for yay ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$YAY_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'yay'
    else
      # libscript_native implementation
      if [ -f /etc/alpine-release ]; then
        log_info 'yay is only for Arch Linux. Skipping installation.'
        exit 0
      fi

      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/yay/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing yay ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yay/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/yay/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/yay" || true
              chmod +x "${TARGET_DIR}/bin/yay" || true
            fi
          fi
        else
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
          URL="https://github.com/Jguer/yay/releases/download/v${EXACT_VERSION}/yay_${EXACT_VERSION}_${ARCH}.tar.gz"
          TEMP_FILE=$(mktemp)
          libscript_depends 'curl' 'tar' || true
          if ! libscript_download "$URL" "$TEMP_FILE.tar.gz"; then
            log_error "Failed to download yay from $URL"
            rm -f "$TEMP_FILE.tar.gz"
            exit 1
          fi
          tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}/bin" --strip-components=1 "yay_${EXACT_VERSION}_${ARCH}/yay" || true
          chmod +x "${TARGET_DIR}/bin/yay" || true
          rm -f "$TEMP_FILE.tar.gz"
        fi
      else
        log_info "yay ${VERSION} is already installed."
      fi
      libscript_symlink_alias "yay" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "yay" "$ACTION" "$VERSION" "${YAY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
