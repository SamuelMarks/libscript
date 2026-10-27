#!/bin/sh
# ## Overview
# Generic setup module for azure-cli.
# 
# ## Usage
# Execute this script to perform generic initialization steps for azure-cli.

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

AZURE_CLI_INSTALL_METHOD="$(libscript_resolve_install_method "AZURE_CLI")"
ACTION="${ACTION:-install}"
VERSION="${AZURE_CLI_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote azure-cli 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "azure-cli" "$ACTION" "$VERSION" "${AZURE_CLI_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${AZURE_CLI_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${AZURE_CLI_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/Azure/azure-cli" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "azure-cli" "$ACTION" "$VERSION" "${AZURE_CLI_INSTALL_METHOD}"
    ;;
  download)
    if [ "$AZURE_CLI_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading azure-cli ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure-cli..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure-cli"
      if [ -n "${AZURE_CLI_DOWNLOAD_URL:-}" ]; then
        libscript_download "${AZURE_CLI_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure-cli/azure-cli-${VERSION}.tar.gz"
      else
        log_warn "AZURE_CLI_DOWNLOAD_URL is not defined for azure-cli ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$AZURE_CLI_INSTALL_METHOD" = "system" ]; then
      if command -v dnf >/dev/null 2>&1; then
        AZURE_CLI_INSTALL_METHOD='libscript_native'
      else
        libscript_depends 'azure-cli'
      fi
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/azure-cli/${EXACT_VERSION}"
      log_info "DEBUG: TARGET_DIR='${TARGET_DIR}', EXACT_VERSION='${EXACT_VERSION}', VERSION='${VERSION}'"
      log_info "DEBUG: ls -la $TARGET_DIR : $(ls -la "$TARGET_DIR" 2>&1 || true)"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing azure-cli ${VERSION} natively to ${TARGET_DIR}..."
        if [ -f /etc/alpine-release ] || [ "${TARGET_OS:-}" = "alpine" ] || [ "${TARGET_OS:-}" = "rhel" ] || [ "${PKG_MGR:-}" = "dnf" ]; then
          log_info "Installing azure-cli via pip on ${TARGET_OS:-system}..."
          if command -v dnf >/dev/null 2>&1; then
            libscript_depends python3-pip || true
            priv pip3 install azure-cli || true
          else
            libscript_depends 'python3' 'py3-pip'
            python3 -m pip install --break-system-packages azure-cli || true
          fi
          mkdir -p "${TARGET_DIR}/bin"
          if [ -x "/usr/local/bin/az" ]; then
            ln -sf "/usr/local/bin/az" "${TARGET_DIR}/bin/az"
          elif [ -x "$HOME/.local/bin/az" ]; then
            ln -sf "$HOME/.local/bin/az" "${TARGET_DIR}/bin/az"
          elif command -v az >/dev/null 2>&1; then
            ln -sf "$(command -v az)" "${TARGET_DIR}/bin/az"
          fi
        elif [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] && [ -n "${PKG_MGR:-}" ]; then
          log_info 'Falling back to system package manager for azure-cli...'
          libscript_depends 'azure-cli'
          mkdir -p "${TARGET_DIR}/bin"
          if command -v az >/dev/null 2>&1; then
            ln -sf "$(command -v az)" "${TARGET_DIR}/bin/az"
          fi
        else
          libscript_fetch_stdout "https://aka.ms/InstallAzureCli" | sh || true
          mkdir -p "${TARGET_DIR}/bin"
          if command -v az >/dev/null 2>&1; then
            ln -sf "$(command -v az)" "${TARGET_DIR}/bin/az"
          fi
        fi
      else
        log_info "azure-cli ${VERSION} is already installed."
      fi
      libscript_symlink_alias "azure-cli" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "azure-cli" "$ACTION" "$VERSION" "${AZURE_CLI_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
