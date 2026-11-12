#!/bin/sh
# ## Overview
# Generic setup script for the tzdata component implementing the Version Manager Contract.
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

TZDATA_INSTALL_METHOD="${TZDATA_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${TZDATA_VERSION:-latest}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='eggert/tz'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/eggert/tz/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='2024b'
      fi
    else
      EXACT_VERSION='2024b'
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
  _rust_target="${_arch_x86}-unknown-linux-musl"
  case "${_os_tok}:${_arch_x86}" in
    linux:aarch64) _rust_target='aarch64-unknown-linux-gnu' ;;
    linux:*) _rust_target="${_arch_x86}-unknown-linux-musl" ;;
    darwin:*) _rust_target="${_arch_x86}-apple-darwin" ;;
    freebsd:*) _rust_target="${_arch_x86}-unknown-freebsd" ;;
  esac
  printf '%s\n' "$_tpl" | sed \
    -e "s/{VERSION}/${EXACT_VERSION}/g" \
    -e "s/{OS}/${_os_tok}/g" \
    -e "s/{OS_TITLE}/${_os_title}/g" \
    -e "s/{ARCH}/${_arch_x86}/g" \
    -e "s/{ARCH_GO}/${_arch_go}/g" \
    -e "s/{RUST_TARGET}/${_rust_target}/g"
}

# ## stage_tzdata_sysroot
# Stages /etc/timezone and /etc/localtime symlink into LIBSCRIPT_TARGET_SYSROOT when configured.
stage_tzdata_sysroot() {
  if [ -z "${LIBSCRIPT_TARGET_SYSROOT:-}" ]; then
    return 0
  fi
  _tz_val="${TZDATA_TIMEZONE:-UTC}"
  mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/etc" "${LIBSCRIPT_TARGET_SYSROOT}/var/lib/libscript/stamps"
  printf '%s\n' "$_tz_val" > "${LIBSCRIPT_TARGET_SYSROOT}/etc/timezone"
  ln -sf "../usr/share/zoneinfo/${_tz_val}" "${LIBSCRIPT_TARGET_SYSROOT}/etc/localtime"
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "${LIBSCRIPT_TARGET_SYSROOT}/var/lib/libscript/stamps/.stamp.tzdata"
}

case "$ACTION" in
  ls)
    if [ "${TZDATA_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tzdata" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tzdata"
    else
      if command -v 'zdump' >/dev/null 2>&1; then
        'zdump' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${TZDATA_RELEASES_URL:-https://data.iana.org/time-zones/releases/}"
    printf '[ls-remote] Fetching available tzdata versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tzdata/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'tzdata' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'tzdata' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://data.iana.org/time-zones/releases/tzdb-{VERSION}.tar.lz'
    URL="${TZDATA_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/tzdata"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading tzdata %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${TZDATA_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tzdata/${EXACT_VERSION}"
      _def_src_url='https://data.iana.org/time-zones/releases/tzdb-{VERSION}.tar.lz'
      SRC_URL="${TZDATA_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'tzdata' "$EXACT_VERSION" 'zdump' 'c' 'make' "$SRC_URL"
      libscript_symlink_alias 'tzdata' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${TZDATA_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'tzdata'
      stage_tzdata_sysroot
    elif [ "${TZDATA_INSTALL_METHOD}" = "nix" ] || [ "${TZDATA_INSTALL_METHOD}" = "guix" ] || [ "${TZDATA_INSTALL_METHOD}" = "spack" ] || [ "${TZDATA_INSTALL_METHOD}" = "brew" ] || [ "${TZDATA_INSTALL_METHOD}" = "winget" ] || [ "${TZDATA_INSTALL_METHOD}" = "choco" ] || [ "${TZDATA_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${TZDATA_INSTALL_METHOD}" 'tzdata'
      stage_tzdata_sysroot
    else
      resolve_exact_version
      stage_tzdata_sysroot
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/tzdata/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/zdump" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'tzdata' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'tzdata' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'tzdata' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='https://data.iana.org/time-zones/releases/tzdb-{VERSION}.tar.lz'
      URL="${TZDATA_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'tzdata'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/tzdata/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/tzdata-$$.archive"
        PACKAGE_NAME='tzdata' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/zdump"
          chmod +x "$TARGET_DIR/bin/zdump"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/zdump" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/zdump" ] || [ -f "$_sub/bin/zdump.sh" ] || [ -f "$_sub/sbin/zdump" ] || [ -f "$_sub/zdump" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/zdump" ] && [ -f "$TARGET_DIR/bin/zdump.sh" ]; then
        chmod +x "$TARGET_DIR/bin/zdump.sh"
        ln -sf "zdump.sh" "$TARGET_DIR/bin/zdump"
      fi
      if [ ! -x "$TARGET_DIR/bin/zdump" ] && [ -f "$TARGET_DIR/sbin/zdump" ]; then
        chmod +x "$TARGET_DIR/sbin/zdump"
        ln -sf "../sbin/zdump" "$TARGET_DIR/bin/zdump"
      fi
      if [ ! -x "$TARGET_DIR/bin/zdump" ] && [ -f "$TARGET_DIR/zdump" ]; then
        chmod +x "$TARGET_DIR/zdump"
        ln -sf "../zdump" "$TARGET_DIR/bin/zdump"
      fi
      if [ ! -x "$TARGET_DIR/bin/zdump" ]; then
        for _entry in $(ls -1 "$TARGET_DIR" 2>/dev/null || true); do
          case "$_entry" in
            zdump-*|zdump_*)
              if [ -f "$TARGET_DIR/$_entry" ]; then
                chmod +x "$TARGET_DIR/$_entry"
                ln -sf "../$_entry" "$TARGET_DIR/bin/zdump"
                break
              fi
              ;;
          esac
        done
      fi
      if [ -f "$TARGET_DIR/bin/zdump" ]; then
        chmod +x "$TARGET_DIR/bin/zdump"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'tzdata' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'tzdata' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'tzdata' "$ACTION" "$VERSION" "${TZDATA_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
