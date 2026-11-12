#!/bin/sh
# ## Overview
# Generic setup script for the haproxy component implementing the Version Manager Contract.
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

HAPROXY_INSTALL_METHOD="${HAPROXY_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
ACTION="${ACTION:-install}"
VERSION="${HAPROXY_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='haproxy/haproxy'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/haproxy/haproxy/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='3.1.2'
      fi
    else
      EXACT_VERSION='3.1.2'
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
    if [ "${HAPROXY_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/haproxy" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/haproxy"
    else
      if command -v 'haproxy' >/dev/null 2>&1; then
        'haproxy' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${HAPROXY_RELEASES_URL:-https://api.github.com/repos/haproxy/haproxy/tags}"
    printf '[ls-remote] Fetching available haproxy versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/haproxy/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'haproxy' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'haproxy' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://www.haproxy.org/download/3.1/src/haproxy-{VERSION}.tar.gz'
    URL="${HAPROXY_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/haproxy"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading haproxy %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${HAPROXY_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/haproxy/${EXACT_VERSION}"
      _def_src_url='https://www.haproxy.org/download/3.1/src/haproxy-{VERSION}.tar.gz'
      SRC_URL="${HAPROXY_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'haproxy' "$EXACT_VERSION" 'haproxy' 'c' 'make' "$SRC_URL"
      libscript_symlink_alias 'haproxy' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${HAPROXY_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'haproxy'
    elif [ "${HAPROXY_INSTALL_METHOD}" = "nix" ] || [ "${HAPROXY_INSTALL_METHOD}" = "guix" ] || [ "${HAPROXY_INSTALL_METHOD}" = "spack" ] || [ "${HAPROXY_INSTALL_METHOD}" = "brew" ] || [ "${HAPROXY_INSTALL_METHOD}" = "winget" ] || [ "${HAPROXY_INSTALL_METHOD}" = "choco" ] || [ "${HAPROXY_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${HAPROXY_INSTALL_METHOD}" 'haproxy'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/haproxy/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/haproxy" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'haproxy' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'haproxy' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'haproxy' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='https://www.haproxy.org/download/3.1/src/haproxy-{VERSION}.tar.gz'
      URL="${HAPROXY_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'haproxy'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/haproxy/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/haproxy-$$.archive"
        PACKAGE_NAME='haproxy' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/haproxy"
          chmod +x "$TARGET_DIR/bin/haproxy"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/haproxy" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/haproxy" ] || [ -f "$_sub/bin/haproxy.sh" ] || [ -f "$_sub/sbin/haproxy" ] || [ -f "$_sub/haproxy" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/haproxy" ] && [ -f "$TARGET_DIR/bin/haproxy.sh" ]; then
        chmod +x "$TARGET_DIR/bin/haproxy.sh"
        ln -sf "haproxy.sh" "$TARGET_DIR/bin/haproxy"
      fi
      if [ ! -x "$TARGET_DIR/bin/haproxy" ] && [ -f "$TARGET_DIR/sbin/haproxy" ]; then
        chmod +x "$TARGET_DIR/sbin/haproxy"
        ln -sf "../sbin/haproxy" "$TARGET_DIR/bin/haproxy"
      fi
      if [ ! -x "$TARGET_DIR/bin/haproxy" ] && [ -f "$TARGET_DIR/haproxy" ]; then
        chmod +x "$TARGET_DIR/haproxy"
        ln -sf "../haproxy" "$TARGET_DIR/bin/haproxy"
      fi
      if [ -f "$TARGET_DIR/bin/haproxy" ]; then
        chmod +x "$TARGET_DIR/bin/haproxy"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'haproxy' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'haproxy' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'haproxy' "$ACTION" "$VERSION" "${HAPROXY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
