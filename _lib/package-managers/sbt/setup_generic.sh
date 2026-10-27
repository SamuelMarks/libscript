#!/bin/sh
# ## Overview
# Generic setup module for sbt.
# 
# ## Usage
# Execute this script to perform generic initialization steps for sbt.

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

SBT_INSTALL_METHOD="$(libscript_resolve_install_method "SBT")"
ACTION="${ACTION:-install}"
VERSION="${SBT_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote sbt 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "sbt" "$ACTION" "$VERSION" "${SBT_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${SBT_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${SBT_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/sbt/sbt" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    if [ "$SBT_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System packages do not support use here.'
    else
      resolve_exact_version
      libscript_symlink_alias "sbt" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "sbt ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "sbt" "default" "${EXACT_VERSION}"
      log_info "Set default sbt version to ${EXACT_VERSION}."
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env sbt \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$SBT_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading sbt ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt..."
        libscript_depends 'java'
        libscript_depends 'bash'


      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt"
      if [ -n "${SBT_DOWNLOAD_URL:-}" ]; then
        libscript_download "${SBT_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/sbt/sbt-${VERSION}.tar.gz"
      else
        log_warn "SBT_DOWNLOAD_URL is not defined for sbt ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$SBT_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'sbt'
    else
      # libscript_native implementation
      resolve_exact_version
      if [ "${EXACT_VERSION}" = "latest" ]; then
         libscript_depends 'curl'
         EXACT_VERSION=$(libscript_fetch_stdout "https://api.github.com/repos/sbt/sbt/releases/latest" | grep -oE "\"tag_name\": *\"v[^\"]+\"" | sed -E "s/.*\"v([^\"]+)\".*/\1/" | head -n 1)
         if [ -z "${EXACT_VERSION}" ] || [ "${EXACT_VERSION}" = "latest" ]; then EXACT_VERSION="1.10.7"; fi
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/sbt/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing sbt ${VERSION} natively to ${TARGET_DIR}..."
        libscript_depends 'java'
        libscript_depends 'bash'


        mkdir -p "${TARGET_DIR}/bin"
        if [ "$(uname -s)" = "FreeBSD" ]; then
          libscript_depends 'sbt'
          if command -v sbt >/dev/null 2>&1; then
            ln -sf "$(command -v sbt)" "${TARGET_DIR}/bin/sbt"
          fi
        else
          URL="https://github.com/sbt/sbt/releases/download/v${EXACT_VERSION}/sbt-${EXACT_VERSION}.tgz"
          TEMP_FILE=$(mktemp)
          libscript_depends 'curl'
          libscript_depends 'tar'
          libscript_download "$URL" "$TEMP_FILE.tgz"
          tar -xzf "$TEMP_FILE.tgz" -C "${TARGET_DIR}" --strip-components=1
          rm -f "$TEMP_FILE.tgz"
        fi
      else
        log_info "sbt ${VERSION} is already installed."
      fi
      libscript_symlink_alias "sbt" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "sbt" "$ACTION" "$VERSION" "${SBT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
