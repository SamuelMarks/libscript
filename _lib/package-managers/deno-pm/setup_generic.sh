#!/bin/sh
# ## Overview
# Generic setup module for deno-pm.
# 
# ## Usage
# Execute this script to perform generic initialization steps for deno-pm.

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

DENO_PM_INSTALL_METHOD="${DENO_PM_INSTALL_METHOD:-system}"
DENO_PM_INSTALL_METHOD="$(libscript_resolve_install_method "DENO_PM")"
ACTION="${ACTION:-install}"
VERSION="${DENO_PM_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote deno-pm 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "deno-pm" "$ACTION" "$VERSION" "${DENO_PM_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${DENO_PM_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${DENO_PM_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/rycont/pm-b310-w2-reversing-deno" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "deno-pm" "$ACTION" "$VERSION" "${DENO_PM_INSTALL_METHOD}"
    ;;
  download)
    if [ "$DENO_PM_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading deno-pm ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/deno-pm..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/deno-pm"
      if [ -n "${DENO_PM_DOWNLOAD_URL:-}" ]; then
        libscript_download "${DENO_PM_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/deno-pm/deno-pm-${VERSION}.tar.gz"
      else
        log_warn "DENO_PM_DOWNLOAD_URL is not defined for deno-pm ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$DENO_PM_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'deno-pm'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/deno-pm/${EXACT_VERSION}"
      if [ "${TARGET_OS:-}" = "alpine" ] || [ "$UNAME_LOWER" = "freebsd" ]; then
        log_info "Configuring deno-pm for ${TARGET_OS:-$UNAME_LOWER}..."
        libscript_depends 'deno' || true
        mkdir -p "${TARGET_DIR}/bin"
        _deno_bin=""
        if [ -x /usr/bin/deno ]; then
          _deno_bin='/usr/bin/deno'
        elif [ -x /usr/local/bin/deno ]; then
          _deno_bin='/usr/local/bin/deno'
        elif command -v deno >/dev/null 2>&1; then
          _deno_bin="$(command -v deno)"
        fi
        if [ -n "$_deno_bin" ] && [ "$_deno_bin" != "${TARGET_DIR}/bin/deno" ]; then
          rm -f "${TARGET_DIR}/bin/deno"
          ln -sf "$_deno_bin" "${TARGET_DIR}/bin/deno"
        fi
      elif [ ! -d "${TARGET_DIR}" ] || [ ! -x "${TARGET_DIR}/bin/deno" ]; then
        log_info "Installing deno-pm ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        libscript_depends 'curl' 'unzip' || true
        libscript_fetch_stdout "https://deno.land/install.sh" | DENO_INSTALL="${TARGET_DIR}" sh || true
      else
        log_info "deno-pm ${VERSION} is already installed."
      fi
      libscript_symlink_alias "deno-pm" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "deno-pm" "$ACTION" "$VERSION" "${DENO_PM_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
