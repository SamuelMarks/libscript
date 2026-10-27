#!/bin/sh
# ## Overview
# Generic setup module for nats.
# 
# ## Usage
# Execute this script to perform generic initialization steps for nats.

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

NATS_INSTALL_METHOD="$(libscript_resolve_install_method "NATS")"
ACTION="${ACTION:-install}"
VERSION="${NATS_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote nats 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "nats" "$ACTION" "$VERSION" "${NATS_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${NATS_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${NATS_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/nats-io/nats-server" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "nats" "$ACTION" "$VERSION" "${NATS_INSTALL_METHOD}"
    ;;
  download)
    if [ "$NATS_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading nats ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nats..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nats"
      if [ -n "${NATS_DOWNLOAD_URL:-}" ]; then
        libscript_download "${NATS_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nats/nats-${VERSION}.tar.gz"
      else
        log_warn "NATS_DOWNLOAD_URL is not defined for nats ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$NATS_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "nats"; then
        log_info 'System package manager unavailable for nats. Falling back to native...'
        NATS_INSTALL_METHOD='libscript_native'
      fi
    fi
    # libscript_native implementation
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nats/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      log_info "Installing nats ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nats/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info 'Extracting from cache...'
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nats/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/nats" || true
            chmod +x "${TARGET_DIR}/bin/nats" || true
          fi
        fi
      else
        if [ -n "${NATS_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${NATS_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${NATS_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${NATS_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/nats" || true
            chmod +x "${TARGET_DIR}/bin/nats" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          if [ "$UNAME_LOWER" = "linux" ]; then
            _actual_version="${EXACT_VERSION}"
            if [ "${_actual_version}" = "latest" ] || [ "${_actual_version}" = "" ]; then
              _actual_version=$(libscript_fetch_stdout "https://api.github.com/repos/nats-io/nats-server/releases/latest" | grep -oE '"tag_name":[[:space:]]*"v[^"]+"' | sed -E 's/.*"v([^"]+)".*/v\1/' | head -n 1)
              [ -z "$_actual_version" ] && _actual_version="v2.10.22"
            fi
            case "${ARCH:-}" in
              aarch64|arm64) _nats_arch="arm64" ;;
              *) _nats_arch="amd64" ;;
            esac
            DL_URL="https://github.com/nats-io/nats-server/releases/download/${_actual_version}/nats-server-${_actual_version}-linux-${_nats_arch}.tar.gz"
            TEMP_FILE=$(mktemp)
            libscript_download "$DL_URL" "$TEMP_FILE"
            tar -xzf "$TEMP_FILE" -C "$TARGET_DIR" --strip-components=1 || true
            mkdir -p "${TARGET_DIR}/bin"
            if [ -f "${TARGET_DIR}/nats-server" ]; then
              mv "${TARGET_DIR}/nats-server" "${TARGET_DIR}/bin/nats-server"
            fi
            rm -f "$TEMP_FILE"
          elif [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
            log_info 'Falling back to system package manager for nats...'
            libscript_depends 'nats-server'
          else
            log_warn "No download URL provided for nats ${VERSION}."
          fi
        fi
      fi
    else
      log_info "nats ${VERSION} is already installed."
    fi
    libscript_symlink_alias "nats" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "nats" "$ACTION" "$VERSION" "${NATS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
