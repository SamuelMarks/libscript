#!/bin/sh
# ## Overview
# Generic setup script for the toybox component supporting MS-DOS (dos32), Windows native (MSVC), and Linux builds.
#
# ## Usage
# Invoked internally by the toybox component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

TOYBOX_INSTALL_METHOD="${TOYBOX_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${TOYBOX_VERSION:-latest}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/toybox-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact toybox version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
      _rel_api="${TOYBOX_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/toybox-windows/releases/latest}"
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION='0.8.15'
    else
      EXACT_VERSION='0.8.11'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_default_toybox_url
# Computes the target-specific download URL for MS-DOS (dos32), Windows native (MSVC), or Linux static builds.
resolve_default_toybox_url() {
  if [ -n "${TOYBOX_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${TOYBOX_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    printf 'https://github.com/SamuelMarks/toybox-windows/releases/download/v%s/toybox-%s-dos32.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    printf 'https://github.com/SamuelMarks/toybox-windows/releases/download/v%s/toybox-%s-%s.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    return 0
  fi
  if [ "${UNAME_LOWER:-linux}" = 'linux' ]; then
    _tb_arch='x86_64'
    case "${ARCH:-x86_64}" in
      aarch64|arm64) _tb_arch='aarch64' ;;
      i386|i686|x86) _tb_arch='i686' ;;
      *) _tb_arch='x86_64' ;;
    esac
    printf 'https://landley.net/toybox/downloads/binaries/%s/toybox-%s\n' "${EXACT_VERSION}" "${_tb_arch}"
    return 0
  fi
  printf '%s\n' ''
}

# ## materialize_toybox_shims
# Materializes per-applet hardlinks/symlinks or .bat trampolines in TARGET_DIR/bin when TOYBOX_INSTALL_SHIMS=1 and freebsd-usr-bin is not installed.
materialize_toybox_shims() {
  _mts_dir="$1"
  _mts_bin="$2"
  case "${TOYBOX_INSTALL_SHIMS:-0}" in
    1|true|TRUE|yes|YES) ;;
    *) return 0 ;;
  esac
  _mts_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  if [ -f "${_mts_home}/freebsd-usr-bin/default/bin/sed" ] || [ -f "${_mts_home}/freebsd-usr-bin/default/bin/sed.exe" ]; then
    printf '[INFO] freebsd-usr-bin is installed; skipping toybox applet shims.\n'
    return 0
  fi
  mkdir -p "${_mts_dir}/bin"
  for _mts_app in basename cat cmp comm cp cut date diff dirname env file find grep head ln ls mktemp mv paste patch printf readlink realpath rm rmdir sed sha1sum sha256sum sleep sort stat tail tee touch tr uname uniq wc which xargs mkdir; do
    if [ "${TARGET_OS:-}" = 'msdos' ]; then
      printf '@echo off\r\n%s %s %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9\r\n' "${_mts_bin}" "${_mts_app}" > "${_mts_dir}/bin/${_mts_app}.bat"
    elif [ "${TARGET_OS:-}" = 'windows' ]; then
      printf '@echo off\r\n"%%~dp0%s" %s %%*\r\n' "${_mts_bin}" "${_mts_app}" > "${_mts_dir}/bin/${_mts_app}.bat"
      chmod +x "${_mts_dir}/bin/${_mts_app}.bat" 2>/dev/null || true
    else
      if ! ln -f "${_mts_dir}/bin/${_mts_bin}" "${_mts_dir}/bin/${_mts_app}" 2>/dev/null; then
        ln -sf "${_mts_bin}" "${_mts_dir}/bin/${_mts_app}"
      fi
    fi
  done
}

case "$ACTION" in
  ls)
    if [ "${TOYBOX_INSTALL_METHOD}" = 'libscript_native' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/toybox" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/toybox"
    else
      if command -v toybox >/dev/null 2>&1; then
        toybox --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${TOYBOX_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/toybox-windows/releases/latest}"
    printf '[ls-remote] Fetching available toybox versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'toybox' "${EXACT_VERSION}")
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'toybox' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'toybox' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_toybox_url)
    if [ -z "$URL" ]; then
      URL="https://landley.net/toybox/downloads/toybox-${EXACT_VERSION}.tar.gz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/toybox"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading toybox %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='toybox' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${TOYBOX_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      SRC_URL="${TOYBOX_DOWNLOAD_URL:-https://landley.net/toybox/downloads/toybox-${EXACT_VERSION}.tar.gz}"
      libscript_build_component_from_source 'toybox' "$EXACT_VERSION" 'toybox' 'c' 'make-defconfig' "$SRC_URL"
      libscript_symlink_alias 'toybox' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'toybox' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${TOYBOX_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'toybox'
    elif [ "${TOYBOX_INSTALL_METHOD}" = 'nix' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'guix' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'spack' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'brew' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'winget' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'choco' ] || [ "${TOYBOX_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${TOYBOX_INSTALL_METHOD}" 'toybox'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir 'toybox' "${EXACT_VERSION}")
      _bin_name='toybox'
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _bin_name='toybox.exe'
      fi
      if [ -f "${TARGET_DIR}/bin/${_bin_name}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] toybox %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
        materialize_toybox_shims "${TARGET_DIR}" "${_bin_name}"
        libscript_symlink_alias 'toybox' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'toybox' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_toybox_url)
      if [ -z "$URL" ]; then
        SRC_URL="https://landley.net/toybox/downloads/toybox-${EXACT_VERSION}.tar.gz"
        libscript_build_component_from_source 'toybox' "$EXACT_VERSION" 'toybox' 'c' 'make-defconfig' "$SRC_URL"
        libscript_symlink_alias 'toybox' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'toybox' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/toybox/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/toybox-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='toybox' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${TOYBOX_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/toybox-windows/releases/download/v${EXACT_VERSION}/toybox-${EXACT_VERSION}-dos32.exe"
            TMP_FILE="${TMPDIR:-/tmp}/toybox-$$.exe"
            PACKAGE_NAME='toybox' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${TOYBOX_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            _win_arch=$(resolve_win_arch)
            URL="https://github.com/SamuelMarks/toybox-windows/releases/download/v${EXACT_VERSION}/toybox-${EXACT_VERSION}-${_win_arch}.exe"
            TMP_FILE="${TMPDIR:-/tmp}/toybox-$$.exe"
            PACKAGE_NAME='toybox' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      case "$URL" in
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          for _cand in "$TARGET_DIR/toybox.exe" "$TARGET_DIR/TOYBOX.EXE" "$TARGET_DIR/bin/toybox.exe" "$TARGET_DIR/bin/TOYBOX.EXE"; do
            if [ -f "$_cand" ] && [ "$_cand" != "$TARGET_DIR/bin/${_bin_name}" ]; then
              cp -f "$_cand" "$TARGET_DIR/bin/${_bin_name}"
              break
            fi
          done
          for _ext in 'DOS32A.EXE' 'DOS4GW.EXE' 'dos32a.exe' 'dos4gw.exe'; do
            if [ -f "$TARGET_DIR/${_ext}" ] && [ ! -f "$TARGET_DIR/bin/${_ext}" ]; then
              cp -f "$TARGET_DIR/${_ext}" "$TARGET_DIR/bin/${_ext}"
            fi
          done
          ;;
        *.tar.gz|*.tgz)
          tar -xzf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *)
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/${_bin_name}"
          ;;
      esac
      if [ -f "$TARGET_DIR/bin/${_bin_name}" ]; then
        chmod +x "$TARGET_DIR/bin/${_bin_name}" 2>/dev/null || true
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      materialize_toybox_shims "${TARGET_DIR}" "${_bin_name}"
      libscript_symlink_alias 'toybox' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'toybox' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'toybox' "$ACTION" "$VERSION" "${TOYBOX_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
