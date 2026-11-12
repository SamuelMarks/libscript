#!/bin/sh
# ## Overview
# Generic setup script for the gleam component implementing the Version Manager Contract.
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

GLEAM_INSTALL_METHOD="${GLEAM_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${GLEAM_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='gleam-lang/gleam'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/gleam-lang/gleam/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='1.7.0'
      fi
    else
      EXACT_VERSION='1.7.0'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "${GLEAM_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gleam" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gleam"
    else
      if command -v 'gleam' >/dev/null 2>&1; then
        'gleam' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${GLEAM_RELEASES_URL:-https://api.github.com/repos/gleam-lang/gleam/releases}"
    printf '[ls-remote] Fetching available gleam versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gleam/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'gleam' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'gleam' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://github.com/gleam-lang/gleam/releases/download/v{VERSION}/gleam-v{VERSION}-x86_64-unknown-linux-musl.tar.gz'
    URL="${GLEAM_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gleam"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading gleam %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${GLEAM_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gleam/${EXACT_VERSION}"
      _def_src_url='https://github.com/gleam-lang/gleam/archive/refs/tags/v{VERSION}.tar.gz'
      SRC_URL="${GLEAM_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(printf '%s\n' "$SRC_URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      libscript_build_component_from_source 'gleam' "$EXACT_VERSION" 'gleam' 'c' 'make' "$SRC_URL"
      libscript_symlink_alias 'gleam' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${GLEAM_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'gleam'
    elif [ "${GLEAM_INSTALL_METHOD}" = "nix" ] || [ "${GLEAM_INSTALL_METHOD}" = "guix" ] || [ "${GLEAM_INSTALL_METHOD}" = "spack" ] || [ "${GLEAM_INSTALL_METHOD}" = "brew" ] || [ "${GLEAM_INSTALL_METHOD}" = "winget" ] || [ "${GLEAM_INSTALL_METHOD}" = "choco" ] || [ "${GLEAM_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${GLEAM_INSTALL_METHOD}" 'gleam'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gleam/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/gleam" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'gleam' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'gleam' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'gleam' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _gl_art=''
      case "${UNAME_LOWER:-linux}" in
        darwin*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _gl_art="gleam-v${EXACT_VERSION}-aarch64-apple-darwin.tar.gz" ;;
            *) _gl_art="gleam-v${EXACT_VERSION}-x86_64-apple-darwin.tar.gz" ;;
          esac
          ;;
        linux*)
          case "${ARCH:-x86_64}" in
            aarch64|arm64) _gl_art="gleam-v${EXACT_VERSION}-aarch64-unknown-linux-musl.tar.gz" ;;
            *) _gl_art="gleam-v${EXACT_VERSION}-x86_64-unknown-linux-musl.tar.gz" ;;
          esac
          ;;
      esac
      _def_url=''
      if [ -n "$_gl_art" ]; then
        _def_url="https://github.com/gleam-lang/gleam/releases/download/v${EXACT_VERSION}/${_gl_art}"
      fi
      URL="${GLEAM_DOWNLOAD_URL:-${_def_url}}"
      URL=$(printf '%s\n' "$URL" | sed "s/{VERSION}/${EXACT_VERSION}/g")
      if [ -z "$URL" ]; then
        libscript_depends 'gleam'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/gleam/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/gleam-$$.archive"
        PACKAGE_NAME='gleam' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/gleam"
          chmod +x "$TARGET_DIR/bin/gleam"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/gleam" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/gleam" ] || [ -f "$_sub/gleam" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/gleam" ] && [ -f "$TARGET_DIR/gleam" ]; then
        chmod +x "$TARGET_DIR/gleam"
        ln -sf "../gleam" "$TARGET_DIR/bin/gleam"
      fi
      if [ -f "$TARGET_DIR/bin/gleam" ]; then
        chmod +x "$TARGET_DIR/bin/gleam"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'gleam' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'gleam' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'gleam' "$ACTION" "$VERSION" "${GLEAM_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
