#!/bin/sh
# ## Overview
# Generic setup script for the ccache component implementing the Version Manager Contract.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

CCACHE_INSTALL_METHOD="${CCACHE_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${CCACHE_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='ccache/ccache'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/ccache/ccache/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='4.10.2'
      fi
    else
      EXACT_VERSION="${VERSION}"
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${CCACHE_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ccache" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ccache"
    else
      if command -v 'ccache' >/dev/null 2>&1; then
        'ccache' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${CCACHE_RELEASES_URL:-https://api.github.com/repos/ccache/ccache/releases}"
    printf '[ls-remote] Fetching available ccache versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ccache/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'ccache' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'ccache' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _ls_def_url="https://github.com/ccache/ccache/releases/download/v{VERSION}/ccache-{VERSION}-linux-x86_64.tar.xz"
    URL="${CCACHE_DOWNLOAD_URL:-${_ls_def_url}}"
    URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ccache"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading ccache %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${CCACHE_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ccache/${EXACT_VERSION}"
      _ls_def_url="https://github.com/ccache/ccache/archive/refs/tags/v{VERSION}.tar.gz"
      SRC_URL="${CCACHE_DOWNLOAD_URL:-${_ls_def_url}}"
      SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      libscript_build_component_from_source 'ccache' "$EXACT_VERSION" 'ccache' 'c' 'cmake' "$SRC_URL"
      libscript_symlink_alias 'ccache' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${CCACHE_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'ccache'
    elif [ "${CCACHE_INSTALL_METHOD}" = "nix" ] || [ "${CCACHE_INSTALL_METHOD}" = "guix" ] || [ "${CCACHE_INSTALL_METHOD}" = "spack" ] || [ "${CCACHE_INSTALL_METHOD}" = "brew" ] || [ "${CCACHE_INSTALL_METHOD}" = "winget" ] || [ "${CCACHE_INSTALL_METHOD}" = "choco" ] || [ "${CCACHE_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${CCACHE_INSTALL_METHOD}" 'ccache'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ccache/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/ccache" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'ccache' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'ccache' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'ccache' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _cc_art='ccache-{VERSION}-linux-x86_64.tar.xz'
      case "${UNAME_LOWER:-linux}" in
        darwin*) _cc_art='ccache-{VERSION}-darwin.tar.gz' ;;
        linux*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _cc_art='ccache-{VERSION}-linux-aarch64.tar.xz' ;;
            *) _cc_art='ccache-{VERSION}-linux-x86_64.tar.xz' ;;
          esac
          ;;
      esac
      _ls_def_url="https://github.com/ccache/ccache/releases/download/v{VERSION}/${_cc_art}"
      URL="${CCACHE_DOWNLOAD_URL:-${_ls_def_url}}"
      URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      if [ -z "$URL" ]; then
        libscript_depends 'ccache'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/ccache/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/ccache-$$.archive"
        PACKAGE_NAME='ccache' libscript_download "$URL" "$TMP_FILE"
      fi
      case "$URL" in
        *.tar.gz|*.tgz)
          tar -xzf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.xz|*.txz)
          tar -xJf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xJf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          ;;
        *)
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/ccache"
          chmod +x "$TARGET_DIR/bin/ccache"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/ccache" ] && [ -f "$TARGET_DIR/ccache" ]; then
        mv -f "$TARGET_DIR/ccache" "$TARGET_DIR/bin/ccache"
        chmod +x "$TARGET_DIR/bin/ccache"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'ccache' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'ccache' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'ccache' "$ACTION" "$VERSION" "${CCACHE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
