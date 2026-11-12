#!/bin/sh
# ## Overview
# Generic setup script for the scons component implementing the Version Manager Contract.
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

SCONS_INSTALL_METHOD="${SCONS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
ACTION="${ACTION:-install}"
VERSION="${SCONS_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='SCons/scons'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/SCons/scons/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='4.8.1'
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
    if [ "${SCONS_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/scons" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/scons"
    else
      if command -v 'scons' >/dev/null 2>&1; then
        'scons' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${SCONS_RELEASES_URL:-https://api.github.com/repos/SCons/scons/releases}"
    printf '[ls-remote] Fetching available scons versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/scons/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'scons' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'scons' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _ls_def_url="https://github.com/SCons/scons/releases/download/v{VERSION}/scons-{VERSION}.tar.gz"
    URL="${SCONS_DOWNLOAD_URL:-${_ls_def_url}}"
    URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/scons"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading scons %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${SCONS_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/scons/${EXACT_VERSION}"
      _ls_def_url="https://github.com/SCons/scons/archive/refs/tags/{VERSION}.tar.gz"
      SRC_URL="${SCONS_DOWNLOAD_URL:-${_ls_def_url}}"
      SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      libscript_build_component_from_source 'scons' "$EXACT_VERSION" 'scons' 'python' 'pip' "$SRC_URL"
      libscript_symlink_alias 'scons' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${SCONS_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'scons'
    elif [ "${SCONS_INSTALL_METHOD}" = "nix" ] || [ "${SCONS_INSTALL_METHOD}" = "guix" ] || [ "${SCONS_INSTALL_METHOD}" = "spack" ] || [ "${SCONS_INSTALL_METHOD}" = "brew" ] || [ "${SCONS_INSTALL_METHOD}" = "winget" ] || [ "${SCONS_INSTALL_METHOD}" = "choco" ] || [ "${SCONS_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${SCONS_INSTALL_METHOD}" 'scons'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/scons/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/scons" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'scons' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'scons' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'scons' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _ls_def_url="https://github.com/SCons/scons/releases/download/v{VERSION}/scons-{VERSION}.tar.gz"
      URL="${SCONS_DOWNLOAD_URL:-${_ls_def_url}}"
      URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      if [ -z "$URL" ]; then
        libscript_depends 'scons'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/scons/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/scons-$$.archive"
        PACKAGE_NAME='scons' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/scons"
          chmod +x "$TARGET_DIR/bin/scons"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/scons" ] && [ -f "$TARGET_DIR/scons" ]; then
        mv -f "$TARGET_DIR/scons" "$TARGET_DIR/bin/scons"
        chmod +x "$TARGET_DIR/bin/scons"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'scons' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'scons' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'scons' "$ACTION" "$VERSION" "${SCONS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
