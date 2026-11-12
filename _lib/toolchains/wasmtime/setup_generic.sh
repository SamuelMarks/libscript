#!/bin/sh
# ## Overview
# Generic setup script for the wasmtime component implementing the Version Manager Contract.
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

WASMTIME_INSTALL_METHOD="${WASMTIME_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${WASMTIME_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='bytecodealliance/wasmtime'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/bytecodealliance/wasmtime/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='28.0.0'
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
    if [ "${WASMTIME_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wasmtime" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wasmtime"
    else
      if command -v 'wasmtime' >/dev/null 2>&1; then
        'wasmtime' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${WASMTIME_RELEASES_URL:-https://api.github.com/repos/bytecodealliance/wasmtime/releases}"
    printf '[ls-remote] Fetching available wasmtime versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wasmtime/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'wasmtime' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'wasmtime' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _ls_def_url="https://github.com/bytecodealliance/wasmtime/releases/download/v{VERSION}/wasmtime-v{VERSION}-x86_64-linux.tar.xz"
    URL="${WASMTIME_DOWNLOAD_URL:-${_ls_def_url}}"
    URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/wasmtime"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading wasmtime %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${WASMTIME_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wasmtime/${EXACT_VERSION}"
      _ls_def_url="https://github.com/bytecodealliance/wasmtime/archive/refs/tags/v{VERSION}.tar.gz"
      SRC_URL="${WASMTIME_DOWNLOAD_URL:-${_ls_def_url}}"
      SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      libscript_build_component_from_source 'wasmtime' "$EXACT_VERSION" 'wasmtime' 'rust' 'cargo' "$SRC_URL"
      libscript_symlink_alias 'wasmtime' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${WASMTIME_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'wasmtime'
    elif [ "${WASMTIME_INSTALL_METHOD}" = "nix" ] || [ "${WASMTIME_INSTALL_METHOD}" = "guix" ] || [ "${WASMTIME_INSTALL_METHOD}" = "spack" ] || [ "${WASMTIME_INSTALL_METHOD}" = "brew" ] || [ "${WASMTIME_INSTALL_METHOD}" = "winget" ] || [ "${WASMTIME_INSTALL_METHOD}" = "choco" ] || [ "${WASMTIME_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${WASMTIME_INSTALL_METHOD}" 'wasmtime'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wasmtime/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/wasmtime" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'wasmtime' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'wasmtime' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'wasmtime' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _wt_plat='x86_64-linux'
      case "${UNAME_LOWER:-linux}" in
        darwin*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _wt_plat='aarch64-macos' ;;
            *) _wt_plat='x86_64-macos' ;;
          esac
          ;;
        linux*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _wt_plat='aarch64-linux' ;;
            *) _wt_plat='x86_64-linux' ;;
          esac
          ;;
      esac
      _ls_def_url="https://github.com/bytecodealliance/wasmtime/releases/download/v{VERSION}/wasmtime-v{VERSION}-${_wt_plat}.tar.xz"
      URL="${WASMTIME_DOWNLOAD_URL:-${_ls_def_url}}"
      URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      if [ -z "$URL" ]; then
        libscript_depends 'wasmtime'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/wasmtime/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/wasmtime-$$.archive"
        PACKAGE_NAME='wasmtime' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/wasmtime"
          chmod +x "$TARGET_DIR/bin/wasmtime"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/wasmtime" ] && [ -f "$TARGET_DIR/wasmtime" ]; then
        mv -f "$TARGET_DIR/wasmtime" "$TARGET_DIR/bin/wasmtime"
        chmod +x "$TARGET_DIR/bin/wasmtime"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'wasmtime' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'wasmtime' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'wasmtime' "$ACTION" "$VERSION" "${WASMTIME_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
