#!/bin/sh
# ## Overview
# Generic setup script for the odin component implementing the Version Manager Contract.
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

ODIN_INSTALL_METHOD="${ODIN_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${ODIN_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='odin-lang/Odin'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/odin-lang/Odin/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='dev-2025-01'
      fi
    else
      EXACT_VERSION='dev-2025-01'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${ODIN_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/odin" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/odin"
    else
      if command -v 'odin' >/dev/null 2>&1; then
        'odin' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${ODIN_RELEASES_URL:-https://api.github.com/repos/odin-lang/Odin/releases}"
    printf '[ls-remote] Fetching available odin versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/odin/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'odin' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'odin' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://github.com/odin-lang/Odin/releases/download/{VERSION}/odin-linux-amd64-{VERSION}.tar.gz'
    URL="${ODIN_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/odin"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading odin %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${ODIN_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/odin/${EXACT_VERSION}"
      _def_src_url='https://github.com/odin-lang/Odin/archive/refs/tags/{VERSION}.tar.gz'
      SRC_URL="${ODIN_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      libscript_build_component_from_source 'odin' "$EXACT_VERSION" 'odin' 'c++' 'make' "$SRC_URL"
      libscript_symlink_alias 'odin' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${ODIN_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'odin'
    elif [ "${ODIN_INSTALL_METHOD}" = "nix" ] || [ "${ODIN_INSTALL_METHOD}" = "guix" ] || [ "${ODIN_INSTALL_METHOD}" = "spack" ] || [ "${ODIN_INSTALL_METHOD}" = "brew" ] || [ "${ODIN_INSTALL_METHOD}" = "winget" ] || [ "${ODIN_INSTALL_METHOD}" = "choco" ] || [ "${ODIN_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${ODIN_INSTALL_METHOD}" 'odin'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/odin/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/odin" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'odin' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'odin' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'odin' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _odin_art=''
      case "${UNAME_LOWER:-linux}" in
        darwin*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _odin_art="odin-macos-arm64-${EXACT_VERSION}.zip" ;;
            *) _odin_art="odin-macos-amd64-${EXACT_VERSION}.zip" ;;
          esac
          ;;
        linux*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _odin_art="odin-linux-arm64-${EXACT_VERSION}.tar.gz" ;;
            *) _odin_art="odin-linux-amd64-${EXACT_VERSION}.tar.gz" ;;
          esac
          ;;
      esac
      _def_url=''
      if [ -n "$_odin_art" ]; then
        _def_url="https://github.com/odin-lang/Odin/releases/download/${EXACT_VERSION}/${_odin_art}"
      fi
      URL="${ODIN_DOWNLOAD_URL:-${_def_url}}"
      URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      if [ -z "$URL" ]; then
        libscript_depends 'odin'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/odin/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/odin-$$.archive"
        PACKAGE_NAME='odin' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/odin"
          chmod +x "$TARGET_DIR/bin/odin"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/odin" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/odin" ] || [ -f "$_sub/odin" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/odin" ] && [ -f "$TARGET_DIR/odin" ]; then
        chmod +x "$TARGET_DIR/odin"
        ln -sf "../odin" "$TARGET_DIR/bin/odin"
      fi
      if [ -f "$TARGET_DIR/bin/odin" ]; then
        chmod +x "$TARGET_DIR/bin/odin"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'odin' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'odin' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'odin' "$ACTION" "$VERSION" "${ODIN_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
