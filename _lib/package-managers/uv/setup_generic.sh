#!/bin/sh
# ## Overview
# Generic setup module for uv.
# 
# ## Usage
# Execute this script to perform generic initialization steps for uv with reuse-else-create semantics.

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

UV_INSTALL_METHOD="${UV_INSTALL_METHOD:-libscript_native}"
ACTION="${ACTION:-install}"
VERSION="${UV_VERSION:-latest}"

# ## find_existing_uv
# Searches LIBSCRIPT_HOME, ~/.local/bin, and system PATH for an existing uv binary.
find_existing_uv() {
  _feu_home="${LIBSCRIPT_HOME:-$HOME/.libscript}"
  for _feu_cand in \
    "${_feu_home}/uv/${VERSION}/bin/uv" \
    "${_feu_home}/uv/default/bin/uv" \
    "${REMOTE_HOME:-$HOME}/.local/bin/uv" \
    "${HOME}/.local/bin/uv" \
    "/root/.local/bin/uv" \
    "$(command -v uv 2>/dev/null || true)"; do
    if [ -n "$_feu_cand" ] && [ -x "$_feu_cand" ]; then
      printf '%s\n' "$_feu_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_uv=$(find_existing_uv 2>/dev/null); then
    _uv_ver=$("$_existing_uv" --version 2>/dev/null | awk '{print $2}' || true)
    if [ -n "$_uv_ver" ]; then
      EXACT_VERSION="$_uv_ver"
      return 0
    fi
  fi
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote uv 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/astral-sh/uv/releases/latest" | grep -oE "\"tag_name\": *\"[0-9.]+\"" | sed -E "s/.*\"([0-9.]+)\".*/\1/" | head -n 1)
    fi
    [ -z "${EXACT_VERSION:-}" ] && EXACT_VERSION="latest"
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "uv" "$ACTION" "$VERSION" "${UV_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${UV_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${UV_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      git ls-remote --tags "https://github.com/astral-sh/uv" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "uv" "$ACTION" "$VERSION" "${UV_INSTALL_METHOD}"
    ;;
  download)
    if [ "$UV_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_uv >/dev/null 2>&1; then
        log_info '[REUSE] uv is already installed; skipping download.'
        exit 0
      fi
      log_info "Downloading uv ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/uv..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/uv"
      if [ -n "${UV_DOWNLOAD_URL:-}" ]; then
        libscript_download "${UV_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/uv/uv-${VERSION}.tar.gz"
      else
        log_warn "UV_DOWNLOAD_URL is not defined for uv ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_uv=$(find_existing_uv 2>/dev/null); then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/uv/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$_existing_uv" != "${TARGET_DIR}/bin/uv" ]; then
        ln -sf "$_existing_uv" "${TARGET_DIR}/bin/uv" 2>/dev/null || true
      fi
      libscript_symlink_alias "uv" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "uv" "default" "${EXACT_VERSION}"
      if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "uv" ]; then
        libscript_symlink_alias "uv" "$VERSION" "${EXACT_VERSION}"
      fi
      log_info "[REUSE] uv (${EXACT_VERSION}) already installed at ${_existing_uv}."
      exit 0
    fi

    if [ "$UV_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "uv" 2>/dev/null; then
        log_info 'System package manager does not have uv, falling back to standalone install...'
        UV_INSTALL_METHOD='libscript_native'
      fi
    fi

    if [ "$UV_INSTALL_METHOD" = "libscript_native" ]; then
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/uv/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/uv" ]; then
        log_info "Installing uv ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/uv/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/uv/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/uv" || true
              chmod +x "${TARGET_DIR}/bin/uv" || true
            fi
          fi
        else
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then ARCH="aarch64"; fi
          OS=$(uname -s | tr "[:upper:]" "[:lower:]")
          if [ "$OS" = "darwin" ]; then OS="apple-darwin"; elif [ "$OS" = "linux" ]; then OS="unknown-linux-musl"; fi
          if [ "${EXACT_VERSION}" = "latest" ]; then
            URL="https://github.com/astral-sh/uv/releases/latest/download/uv-${ARCH}-${OS}.tar.gz"
          else
            URL="https://github.com/astral-sh/uv/releases/download/${EXACT_VERSION}/uv-${ARCH}-${OS}.tar.gz"
          fi
          TEMP_FILE=$(mktemp)
          libscript_depends 'curl' 'tar' || true
          if ! libscript_download "$URL" "$TEMP_FILE.tar.gz"; then
            log_error "Failed to download uv from $URL"
            rm -f "$TEMP_FILE.tar.gz"
            exit 1
          fi
          tar -xzf "$TEMP_FILE.tar.gz" -C "${TARGET_DIR}/bin" --strip-components=1 || cp "$TEMP_FILE.tar.gz" "${TARGET_DIR}/bin/uv"
          chmod +x "${TARGET_DIR}/bin/uv" || true
          chmod +x "${TARGET_DIR}/bin/uvx" >/dev/null 2>&1 || true
          rm -f "$TEMP_FILE.tar.gz"
        fi
      else
        log_info "uv ${VERSION} is already installed."
      fi
      libscript_symlink_alias "uv" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "uv" "default" "${EXACT_VERSION}"
      if [ -n "${VERSION:-}" ] && [ "${VERSION}" != "uv" ]; then
        libscript_symlink_alias "uv" "$VERSION" "${EXACT_VERSION}"
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "uv" "$ACTION" "$VERSION" "${UV_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
