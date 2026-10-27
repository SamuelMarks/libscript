#!/bin/sh
# ## Overview
# Generic setup module for nimble.
# 
# ## Usage
# Execute this script to perform generic initialization steps for nimble.

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

NIMBLE_INSTALL_METHOD="$(libscript_resolve_install_method "NIMBLE")"
ACTION="${ACTION:-install}"
VERSION="${NIMBLE_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote nimble 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "nimble" "$ACTION" "$VERSION" "${NIMBLE_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${NIMBLE_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${NIMBLE_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/nim-lang/nimble" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "nimble" "$ACTION" "$VERSION" "${NIMBLE_INSTALL_METHOD}"
    ;;
  download)
    if [ "$NIMBLE_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading nimble ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nimble..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nimble"
      if [ -n "${NIMBLE_DOWNLOAD_URL:-}" ]; then
        libscript_download "${NIMBLE_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nimble/nimble-${VERSION}.tar.gz"
      else
        log_warn "NIMBLE_DOWNLOAD_URL is not defined for nimble ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$NIMBLE_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'nimble'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nimble/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/nimble" ]; then
        log_info "Installing nimble ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"

        installed=0
        if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
          log_info 'Attempting system package manager for nimble...'
          if libscript_depends "nimble" 2>/dev/null; then
            if command -v nimble >/dev/null 2>&1; then
              ln -sf "$(command -v nimble)" "${TARGET_DIR}/bin/nimble"
              installed=1
            fi
          fi
        elif command -v brew >/dev/null 2>&1; then
          libscript_depends_via brew nim || true
          if command -v nimble >/dev/null 2>&1; then
            ln -sf "$(command -v nimble)" "${TARGET_DIR}/bin/nimble"
            installed=1
          fi
        fi

        if [ "$installed" = "0" ]; then
          ARCH=$(uname -m)
          NIM_ARCH=""
          case "$ARCH" in
            x86_64|amd64) NIM_ARCH="linux_x64" ;;
            aarch64|arm64) NIM_ARCH="linux_arm64" ;;
            armv7l) NIM_ARCH="linux_armv7l" ;;
            i*86) NIM_ARCH="linux_x32" ;;
            *) NIM_ARCH="" ;;
          esac

          if [ -n "$NIM_ARCH" ] && [ "$UNAME_LOWER" = "linux" ]; then
            log_info 'Downloading standalone Nim bundle containing nimble...'
            NIM_VER=$(libscript_fetch_stdout "https://nim-lang.org/install_unix.html" 2>/dev/null | grep -oE 'nim-[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^nim-//')
            : "${NIM_VER:=2.2.12}"
            NIM_URL="https://nim-lang.org/download/nim-${NIM_VER}-${NIM_ARCH}.tar.xz"
            TEMP_XZ=$(mktemp)
            TEMP_DIR=$(mktemp -d)
            libscript_depends 'curl' 'tar' 'xz-utils' || true
            if libscript_download "$NIM_URL" "$TEMP_XZ"; then
              tar -xJf "$TEMP_XZ" -C "$TEMP_DIR" --strip-components=1 || true
              if [ -f "$TEMP_DIR/bin/nimble" ]; then
                cp -a "$TEMP_DIR/bin/"* "${TARGET_DIR}/bin/" 2>/dev/null || cp "$TEMP_DIR/bin/nimble" "${TARGET_DIR}/bin/nimble"
                chmod +x "${TARGET_DIR}/bin/nimble" || true
                installed=1
              fi
            fi
            rm -rf "$TEMP_XZ" "$TEMP_DIR"
          fi
        fi

        if [ "$installed" = "0" ] && ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nimble/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nimble/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/nimble" || true
              chmod +x "${TARGET_DIR}/bin/nimble" || true
            fi
          fi
        elif [ "$installed" = "0" ]; then
          if [ -n "${NIMBLE_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${NIMBLE_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${NIMBLE_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${NIMBLE_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/nimble" || true
              chmod +x "${TARGET_DIR}/bin/nimble" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
              log_info 'Falling back to system package manager for nimble...'
              libscript_depends 'nimble'
              if command -v nimble >/dev/null 2>&1; then
                ln -sf "$(command -v nimble)" "${TARGET_DIR}/bin/nimble"
              fi
            else
              if [ "$UNAME_LOWER" = "freebsd" ]; then
              log_info 'No native binary for FreeBSD. Falling back to system package manager for nimble...'
              libscript_depends 'nimble'
            else
              log_warn "No download URL provided for nimble ${VERSION}."
            fi
            fi
          fi
        fi
      else
        log_info "nimble ${VERSION} is already installed."
      fi
      libscript_symlink_alias "nimble" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "nimble" "default" "${EXACT_VERSION}"
      if [ "$VERSION" != "latest" ] && [ "$VERSION" != "default" ]; then
        libscript_symlink_alias "nimble" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "nimble" "$ACTION" "$VERSION" "${NIMBLE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
