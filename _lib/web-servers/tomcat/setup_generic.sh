#!/bin/sh
# ## Overview
# Generic setup script for the tomcat component implementing the Version Manager Contract.
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

TOMCAT_INSTALL_METHOD="${TOMCAT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${TOMCAT_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='apache/tomcat'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/apache/tomcat/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='10.1.34'
      fi
    else
      EXACT_VERSION='10.1.34'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_artifact_url
# Substitutes version, OS, and CPU architecture tokens into an artifact URL template.
resolve_artifact_url() {
  _tpl="$1"
  _os_tok="${UNAME_LOWER:-linux}"
  _os_title='Linux'
  case "$_os_tok" in
    darwin*) _os_tok='darwin'; _os_title='Darwin' ;;
    freebsd*) _os_tok='freebsd'; _os_title='FreeBSD' ;;
    sunos*) _os_tok='sunos'; _os_title='SunOS' ;;
    *) _os_tok='linux'; _os_title='Linux' ;;
  esac
  _arch_raw="${ARCH:-x86_64}"
  _arch_x86='x86_64'
  _arch_go='amd64'
  case "$_arch_raw" in
    aarch64|arm64) _arch_x86='aarch64'; _arch_go='arm64' ;;
    x86_64|amd64) _arch_x86='x86_64'; _arch_go='amd64' ;;
    *) _arch_x86="$_arch_raw"; _arch_go="$_arch_raw" ;;
  esac
  printf '%s\n' "$_tpl" | sed \
    -e "s/{VERSION}/${EXACT_VERSION}/g" \
    -e "s/{OS}/${_os_tok}/g" \
    -e "s/{OS_TITLE}/${_os_title}/g" \
    -e "s/{ARCH}/${_arch_x86}/g" \
    -e "s/{ARCH_GO}/${_arch_go}/g"
}

case "$ACTION" in
  ls)
    if [ "${TOMCAT_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tomcat" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tomcat"
    else
      if command -v 'catalina' >/dev/null 2>&1; then
        'catalina' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${TOMCAT_RELEASES_URL:-https://api.github.com/repos/apache/tomcat/tags}"
    printf '[ls-remote] Fetching available tomcat versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tomcat/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'tomcat' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'tomcat' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://archive.apache.org/dist/tomcat/tomcat-10/v{VERSION}/bin/apache-tomcat-{VERSION}.tar.gz'
    URL="${TOMCAT_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tomcat"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading tomcat %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${TOMCAT_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tomcat/${EXACT_VERSION}"
      _def_src_url='https://archive.apache.org/dist/tomcat/tomcat-10/v{VERSION}/src/apache-tomcat-{VERSION}-src.tar.gz'
      SRC_URL="${TOMCAT_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'tomcat' "$EXACT_VERSION" 'catalina' 'java' 'gradle' "$SRC_URL"
      libscript_symlink_alias 'tomcat' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${TOMCAT_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'tomcat'
    elif [ "${TOMCAT_INSTALL_METHOD}" = "nix" ] || [ "${TOMCAT_INSTALL_METHOD}" = "guix" ] || [ "${TOMCAT_INSTALL_METHOD}" = "spack" ] || [ "${TOMCAT_INSTALL_METHOD}" = "brew" ] || [ "${TOMCAT_INSTALL_METHOD}" = "winget" ] || [ "${TOMCAT_INSTALL_METHOD}" = "choco" ] || [ "${TOMCAT_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${TOMCAT_INSTALL_METHOD}" 'tomcat'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tomcat/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/catalina" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'tomcat' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'tomcat' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'tomcat' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='https://archive.apache.org/dist/tomcat/tomcat-10/v{VERSION}/bin/apache-tomcat-{VERSION}.tar.gz'
      URL="${TOMCAT_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'tomcat'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/tomcat/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/tomcat-$$.archive"
        PACKAGE_NAME='tomcat' libscript_download "$URL" "$TMP_FILE"
      fi
      case "$URL" in
        *.tar.gz|*.tgz)
          tar -xzf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.xz|*.txz)
          tar -xJf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xJf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.bz2|*.tbz2)
          tar -xjf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xjf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          ;;
        *)
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/catalina"
          chmod +x "$TARGET_DIR/bin/catalina"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/catalina" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/catalina" ] || [ -f "$_sub/bin/catalina.sh" ] || [ -f "$_sub/sbin/catalina" ] || [ -f "$_sub/catalina" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/catalina" ] && [ -f "$TARGET_DIR/bin/catalina.sh" ]; then
        chmod +x "$TARGET_DIR/bin/catalina.sh"
        ln -sf "catalina.sh" "$TARGET_DIR/bin/catalina"
      fi
      if [ ! -x "$TARGET_DIR/bin/catalina" ] && [ -f "$TARGET_DIR/sbin/catalina" ]; then
        chmod +x "$TARGET_DIR/sbin/catalina"
        ln -sf "../sbin/catalina" "$TARGET_DIR/bin/catalina"
      fi
      if [ ! -x "$TARGET_DIR/bin/catalina" ] && [ -f "$TARGET_DIR/catalina" ]; then
        chmod +x "$TARGET_DIR/catalina"
        ln -sf "../catalina" "$TARGET_DIR/bin/catalina"
      fi
      if [ -f "$TARGET_DIR/bin/catalina" ]; then
        chmod +x "$TARGET_DIR/bin/catalina"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'tomcat' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'tomcat' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'tomcat' "$ACTION" "$VERSION" "${TOMCAT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
