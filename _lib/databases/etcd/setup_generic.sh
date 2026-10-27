#!/bin/sh
# ## Overview
# Generic setup module for etcd.
# 
# ## Usage
# Execute this script to perform generic initialization steps for etcd.

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

ETCD_INSTALL_METHOD="$(libscript_resolve_install_method "ETCD")"
ACTION="${ACTION:-install}"
VERSION="${ETCD_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote etcd 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "etcd" "$ACTION" "$VERSION" "${ETCD_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${ETCD_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${ETCD_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/etcd-io/etcd" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "etcd" "$ACTION" "$VERSION" "${ETCD_INSTALL_METHOD}"
    ;;
  download)
    if [ "$ETCD_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading etcd ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/etcd..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/etcd"
      if [ -n "${ETCD_DOWNLOAD_URL:-}" ]; then
        libscript_download "${ETCD_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/etcd/etcd-${VERSION}.tar.gz"
      else
        log_warn "ETCD_DOWNLOAD_URL is not defined for etcd ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$ETCD_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'etcd'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/etcd/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing etcd ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/etcd/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/etcd/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/etcd" || true
              chmod +x "${TARGET_DIR}/bin/etcd" || true
            fi
          fi
        else
          if [ -n "${ETCD_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${ETCD_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${ETCD_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${ETCD_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/etcd" || true
              chmod +x "${TARGET_DIR}/bin/etcd" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "freebsd" ]; then
              log_info 'No native binary for FreeBSD. Falling back to system package manager for etcd...'
              libscript_depends 'etcd'
              for _b in etcd etcdctl etcdutl; do
                if command -v "$_b" >/dev/null 2>&1; then
                  ln -sf "$(command -v "$_b")" "${TARGET_DIR}/bin/$_b"
                fi
              done
            else
              log_info "No download URL provided for etcd ${VERSION}. Attempting fallback to Github..."
            libscript_depends 'curl' 'tar'
            TEMP_FILE=$(mktemp)
            OS_ARCH=$(uname -m)
            _actual_version="${EXACT_VERSION}"
            if [ "${_actual_version}" = "latest" ] || [ "${_actual_version}" = "" ]; then
              _actual_version=$(libscript_fetch_stdout "https://api.github.com/repos/etcd-io/etcd/releases/latest" | grep -oE '"tag_name":[[:space:]]*"v[^"]+"' | sed -E 's/.*"v([^"]+)".*/v\1/' | head -n 1)
              [ -z "$_actual_version" ] && _actual_version="v3.5.17"
            fi
            # etcd naming: etcd-v3.5.17-linux-arm64.tar.gz
            if [ "$OS_ARCH" = "aarch64" ]; then
              DL_URL="https://github.com/etcd-io/etcd/releases/download/${_actual_version}/etcd-${_actual_version}-linux-arm64.tar.gz"
            elif [ "$OS_ARCH" = "x86_64" ]; then
              DL_URL="https://github.com/etcd-io/etcd/releases/download/${_actual_version}/etcd-${_actual_version}-linux-amd64.tar.gz"
            else
              DL_URL=""
            fi
            if [ -n "$DL_URL" ]; then
                libscript_download "$DL_URL" "${TEMP_FILE}"
                tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}/bin" --strip-components=1 || true
            else
                log_warn "Unsupported architecture $OS_ARCH for etcd."
            fi
            rm -f "${TEMP_FILE}"
          fi
        fi
fi
      else
        log_info "etcd ${VERSION} is already installed."
      fi
      libscript_symlink_alias "etcd" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "etcd" "$ACTION" "$VERSION" "${ETCD_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
