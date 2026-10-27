#!/bin/sh
# ## Overview
# Generic setup module for mamba.
# 
# ## Usage
# Execute this script to perform generic initialization steps for mamba.

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

if [ "${TARGET_OS:-}" = "alpine" ]; then
  log_info 'mamba is not natively supported on Alpine (requires glibc).'
  exit 0
fi

MAMBA_INSTALL_METHOD="$(libscript_resolve_install_method "MAMBA")"
ACTION="${ACTION:-install}"
VERSION="${MAMBA_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote mamba 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "mamba" "$ACTION" "$VERSION" "${MAMBA_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${MAMBA_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${MAMBA_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/mamba-org/mamba" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "mamba" "$ACTION" "$VERSION" "${MAMBA_INSTALL_METHOD}"
    ;;
  download)
    if [ "$MAMBA_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading mamba ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mamba..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mamba"
      if [ -n "${MAMBA_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MAMBA_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mamba/mamba-${VERSION}.tar.gz"
      else
        log_warn "MAMBA_DOWNLOAD_URL is not defined for mamba ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$MAMBA_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'mamba'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mamba/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing mamba ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        
        libscript_depends curl tar bzip2
        if [ -f /etc/alpine-release ]; then
          libscript_depends gcompat || true
        fi
        
        # Download micromamba
        ARCH="$(uname -m)"
        case "${ARCH}" in
          x86_64) MAMBA_ARCH="64" ;;
          aarch64|arm64) MAMBA_ARCH="aarch64" ;;
          *) log_error "Unsupported architecture for mamba: ${ARCH}"; exit 1 ;;
        esac
        
        OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
        
        log_info "Downloading micromamba for ${OS}-${MAMBA_ARCH}..."
        TEMP_DIR=$(mktemp -d)
        TEMP_FILE=$(mktemp)
        if ! libscript_download "https://micro.mamba.pm/api/micromamba/${OS}-${MAMBA_ARCH}/latest" "$TEMP_FILE"; then
          log_error 'Failed to download micromamba'
          rm -rf "$TEMP_DIR" "$TEMP_FILE"
          exit 1
        fi
        tar -xvj -f "$TEMP_FILE" -C "$TEMP_DIR" bin/micromamba || true
        rm -f "$TEMP_FILE"
        if [ -f "$TEMP_DIR/bin/micromamba" ]; then
          cp "$TEMP_DIR/bin/micromamba" "${TARGET_DIR}/bin/mamba"
          cp "$TEMP_DIR/bin/micromamba" "${TARGET_DIR}/bin/micromamba"
          chmod +x "${TARGET_DIR}/bin/mamba" "${TARGET_DIR}/bin/micromamba"
        else
          log_error 'Failed to download or extract micromamba'
          rm -rf "$TEMP_DIR"
          exit 1
        fi
        rm -rf "$TEMP_DIR"
      else
        log_info "mamba ${VERSION} is already installed."
      fi
      libscript_symlink_alias "mamba" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "mamba" "$ACTION" "$VERSION" "${MAMBA_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
