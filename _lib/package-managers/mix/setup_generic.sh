#!/bin/sh
# ## Overview
# Generic setup module for mix.
# 
# ## Usage
# Execute this script to perform generic initialization steps for mix.

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

MIX_INSTALL_METHOD="$(libscript_resolve_install_method "MIX")"
ACTION="${ACTION:-install}"
VERSION="${MIX_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote mix 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "mix" "$ACTION" "$VERSION" "${MIX_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${MIX_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${MIX_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/elixir-lang/elixir" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "mix" "$ACTION" "$VERSION" "${MIX_INSTALL_METHOD}"
    ;;
  download)
    if [ "$MIX_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading mix ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mix..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mix"
      if [ -n "${MIX_DOWNLOAD_URL:-}" ]; then
        libscript_download "${MIX_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mix/mix-${VERSION}.tar.gz"
      else
        log_warn "MIX_DOWNLOAD_URL is not defined for mix ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$MIX_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'mix'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mix/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing mix ${VERSION} natively (by installing elixir)..."
        
        # mix is part of elixir, so we just install elixir
        unset SCRIPT_NAME || true
        ACTION="install" ELIXIR_VERSION="$VERSION" sh "${LIBSCRIPT_ROOT_DIR}/_lib/languages/elixir/setup.sh" install "elixir" "" || exit 1
        
        mkdir -p "${TARGET_DIR}/bin"
        # Link mix from elixir's installation
        ELIXIR_EXACT_VERSION=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote elixir 2>/dev/null | tail -n 1 || printf '%s' "latest")
        if [ "$VERSION" != "latest" ] && [ "$VERSION" != "lts" ] && [ "$VERSION" != "stable" ]; then
          ELIXIR_EXACT_VERSION="$VERSION"
        fi
        
        ELIXIR_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/elixir/${ELIXIR_EXACT_VERSION}"
        if [ -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/elixir/latest/bin/mix" ]; then
          ln -sf "${LIBSCRIPT_HOME:-$HOME/.libscript}/elixir/latest/bin/mix" "${TARGET_DIR}/bin/mix"
        elif [ -f "${ELIXIR_DIR}/bin/mix" ]; then
          ln -sf "${ELIXIR_DIR}/bin/mix" "${TARGET_DIR}/bin/mix"
        elif command -v mix >/dev/null 2>&1; then
          ln -sf "$(command -v mix)" "${TARGET_DIR}/bin/mix"
        fi
      else
        log_info "mix ${VERSION} is already installed."
      fi
      libscript_symlink_alias "mix" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "mix" "$ACTION" "$VERSION" "${MIX_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
