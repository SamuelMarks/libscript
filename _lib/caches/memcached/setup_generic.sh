#!/bin/sh
# ## Overview
# Generic setup module for memcached.
# 
# ## Usage
# Execute this script to perform generic initialization steps for memcached.

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

MEMCACHED_INSTALL_METHOD="$(libscript_resolve_install_method "MEMCACHED")"
ACTION="${ACTION:-install}"
VERSION="${MEMCACHED_VERSION:-latest}"

# ## resolve_exact_version
# Resolves the exact numeric version from version aliases such as latest or stable.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote memcached 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION='1.6.45'
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

if [ -z "${MEMCACHED_DOWNLOAD_URL:-}" ]; then
  case "$TARGET_OS" in
    windows|mingw|cygwin)
      _tmp_ver="${VERSION:-latest}"
      if [ "$_tmp_ver" = "latest" ] || [ "$_tmp_ver" = "lts" ] || [ "$_tmp_ver" = "stable" ]; then
        _tmp_ver=$(git ls-remote --tags "https://github.com/SamuelMarks/memcached-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | tail -n 1 || true)
        if [ -z "$_tmp_ver" ]; then
          _tmp_ver='1.6.45'
        fi
      fi
      _raw_ver="${_tmp_ver#v}"
      MEMCACHED_DOWNLOAD_URL="https://github.com/SamuelMarks/memcached-windows/releases/download/v${_raw_ver}/Memcached-${_raw_ver}-win64.zip"
      ;;
  esac
fi

case "$ACTION" in
  ls)
    libscript_handle_generic_action "memcached" "$ACTION" "$VERSION" "${MEMCACHED_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${MEMCACHED_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${MEMCACHED_RELEASES_URL}" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      case "$TARGET_OS" in
        windows|mingw|cygwin)
          git ls-remote --tags "https://github.com/SamuelMarks/memcached-windows" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
        *)
          git ls-remote --tags "https://github.com/memcached/memcached" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
          ;;
      esac
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "memcached" "$ACTION" "$VERSION" "${MEMCACHED_INSTALL_METHOD}"
    ;;
  download)
    if [ "$MEMCACHED_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading memcached ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/memcached..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/memcached"
      if [ -n "${MEMCACHED_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MEMCACHED_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/memcached/memcached-${VERSION}.zip"
      else
        log_warn "MEMCACHED_DOWNLOAD_URL is not defined for memcached ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$MEMCACHED_INSTALL_METHOD" = "from-source" ]; then
      EXACT_VERSION="${VERSION:-1.6.45}"
      [ "${EXACT_VERSION}" = "latest" ] && EXACT_VERSION="1.6.45"
      libscript_build_component_from_source "memcached" "${EXACT_VERSION}" "memcached" "c" "autotools" "${MEMCACHED_DOWNLOAD_URL:-}"
      exit 0
    fi
    if [ "$MEMCACHED_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'memcached'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/memcached/${EXACT_VERSION}"
      if [ ! -f "${TARGET_DIR}/bin/memcached" ] && [ ! -f "${TARGET_DIR}/bin/memcached.exe" ]; then
        log_info "Installing memcached ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/memcached/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/memcached/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 2>/dev/null || tar -xzf "$cache_file" -C "${TARGET_DIR}" || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
              if [ -d "${TARGET_DIR}/Memcached-${EXACT_VERSION}-win64/bin" ]; then
                cp -r "${TARGET_DIR}/Memcached-${EXACT_VERSION}-win64/bin/"* "${TARGET_DIR}/bin/" 2>/dev/null || true
              elif ls -d "${TARGET_DIR}"/Memcached-*-win64/bin >/dev/null 2>&1; then
                cp -r "${TARGET_DIR}"/Memcached-*-win64/bin/* "${TARGET_DIR}/bin/" 2>/dev/null || true
              fi
            else
              cp "$cache_file" "${TARGET_DIR}/bin/memcached" || true
              chmod +x "${TARGET_DIR}/bin/memcached" || true
            fi
          fi
        else
          if [ -n "${MEMCACHED_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${MEMCACHED_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${MEMCACHED_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 2>/dev/null || tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" || true
            elif case "${MEMCACHED_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
              if [ -d "${TARGET_DIR}/Memcached-${EXACT_VERSION}-win64/bin" ]; then
                cp -r "${TARGET_DIR}/Memcached-${EXACT_VERSION}-win64/bin/"* "${TARGET_DIR}/bin/" 2>/dev/null || true
              elif ls -d "${TARGET_DIR}"/Memcached-*-win64/bin >/dev/null 2>&1; then
                cp -r "${TARGET_DIR}"/Memcached-*-win64/bin/* "${TARGET_DIR}/bin/" 2>/dev/null || true
              fi
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/memcached" || true
              chmod +x "${TARGET_DIR}/bin/memcached" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] || [ "$UNAME_LOWER" = "darwin" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info 'Falling back to system package manager for memcached...'
              libscript_depends 'memcached'
              if command -v memcached >/dev/null 2>&1; then
                ln -sf "$(command -v memcached)" "${TARGET_DIR}/bin/memcached"
                if command -v memcached-tool >/dev/null 2>&1; then
                  ln -sf "$(command -v memcached-tool)" "${TARGET_DIR}/bin/memcached-tool" 2>/dev/null || true
                fi
              fi
            else
              log_warn "No download URL provided for memcached ${VERSION}."
            fi
          fi
        fi
      else
        log_info "memcached ${VERSION} is already installed."
      fi
      libscript_symlink_alias "memcached" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "memcached" "$ACTION" "$VERSION" "${MEMCACHED_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
