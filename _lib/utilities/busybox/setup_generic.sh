#!/bin/sh
# ## Overview
# Generic setup script for the busybox component backed by SamuelMarks/busybox-windows on Windows/MS-DOS and static musl binaries on Linux.
#
# ## Usage
# Invoked internally by the busybox component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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

BUSYBOX_INSTALL_METHOD="${BUSYBOX_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${BUSYBOX_VERSION:-latest}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/busybox-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact busybox version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
      _rel_api="${BUSYBOX_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/busybox-windows/releases/latest}"
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION='1.39.0'
    else
      EXACT_VERSION='1.35.0'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_default_busybox_url
# Computes the target-specific download URL for MS-DOS, Windows native (MSVC), or Linux musl static builds.
resolve_default_busybox_url() {
  if [ -n "${BUSYBOX_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${BUSYBOX_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    printf 'https://github.com/SamuelMarks/busybox-windows/releases/download/v%s/busybox-%s-dos32.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    printf 'https://github.com/SamuelMarks/busybox-windows/releases/download/v%s/busybox-%s-%s.exe\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    return 0
  fi
  if [ "${UNAME_LOWER:-linux}" = 'linux' ]; then
    _bb_arch='x86_64'
    case "${ARCH:-x86_64}" in
      aarch64|arm64) _bb_arch='armv8l' ;;
      i386|i686|x86) _bb_arch='i686' ;;
      *) _bb_arch='x86_64' ;;
    esac
    printf 'https://busybox.net/downloads/binaries/%s-defconfig-multiarch-musl/busybox-%s\n' "${EXACT_VERSION}" "${_bb_arch}"
    return 0
  fi
  printf '%s\n' ''
}

# ## materialize_busybox_shims
# Materializes per-applet hardlinks/symlinks or .bat trampolines in TARGET_DIR/bin when BUSYBOX_INSTALL_SHIMS=1 and freebsd-usr-bin is not installed.
materialize_busybox_shims() {
  _mbs_dir="$1"
  _mbs_bin="$2"
  case "${BUSYBOX_INSTALL_SHIMS:-0}" in
    1|true|TRUE|yes|YES) ;;
    *) return 0 ;;
  esac
  _mbs_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  if [ -f "${_mbs_home}/freebsd-usr-bin/default/bin/sed" ] || [ -f "${_mbs_home}/freebsd-usr-bin/default/bin/sed.exe" ]; then
    printf '[INFO] freebsd-usr-bin is installed; skipping busybox applet shims.\n'
    return 0
  fi
  mkdir -p "${_mbs_dir}/bin"
  for _mbs_app in ash awk basename cat cmp comm cp cut date diff dirname env find grep gunzip gzip head ln ls mktemp mv patch printf rm rmdir sed sh sha1sum sha256sum sleep sort stat tail tar tee touch tr uname uniq unzip wc wget which xargs mkdir; do
    if [ "${TARGET_OS:-}" = 'msdos' ]; then
      printf '@echo off\r\n%s %s %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9\r\n' "${_mbs_bin}" "${_mbs_app}" > "${_mbs_dir}/bin/${_mbs_app}.bat"
    elif [ "${TARGET_OS:-}" = 'windows' ]; then
      printf '@echo off\r\n"%%~dp0%s" %s %%*\r\n' "${_mbs_bin}" "${_mbs_app}" > "${_mbs_dir}/bin/${_mbs_app}.bat"
      chmod +x "${_mbs_dir}/bin/${_mbs_app}.bat" 2>/dev/null || true
    else
      if ! ln -f "${_mbs_dir}/bin/${_mbs_bin}" "${_mbs_dir}/bin/${_mbs_app}" 2>/dev/null; then
        ln -sf "${_mbs_bin}" "${_mbs_dir}/bin/${_mbs_app}"
      fi
    fi
  done
}

case "$ACTION" in
  ls)
    if [ "${BUSYBOX_INSTALL_METHOD}" = 'libscript_native' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/busybox" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/busybox"
    else
      if command -v busybox >/dev/null 2>&1; then
        busybox | head -n 1 || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${BUSYBOX_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/busybox-windows/releases/latest}"
    printf '[ls-remote] Fetching available busybox versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'busybox' "${EXACT_VERSION}")
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      STACK='' ACTION='install' "${THIS_FILE}"
    fi
    libscript_symlink_alias 'busybox' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'busybox' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_busybox_url)
    if [ -z "$URL" ]; then
      printf '%s\n' 'No prebuilt busybox URL resolved for current target.' >&2
      exit 1
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/busybox"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading busybox %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='busybox' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${BUSYBOX_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      SRC_URL="${BUSYBOX_DOWNLOAD_URL:-https://busybox.net/downloads/busybox-${EXACT_VERSION}.tar.bz2}"
      libscript_build_component_from_source 'busybox' "$EXACT_VERSION" 'busybox' 'c' 'make-defconfig' "$SRC_URL"
      libscript_symlink_alias 'busybox' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'busybox' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${BUSYBOX_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'busybox'
    elif [ "${BUSYBOX_INSTALL_METHOD}" = 'nix' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'guix' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'spack' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'brew' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'winget' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'choco' ] || [ "${BUSYBOX_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${BUSYBOX_INSTALL_METHOD}" 'busybox'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir 'busybox' "${EXACT_VERSION}")
      _bin_name='busybox'
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _bin_name='busybox.exe'
      fi
      if [ -f "${TARGET_DIR}/bin/${_bin_name}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] busybox %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
        materialize_busybox_shims "${TARGET_DIR}" "${_bin_name}"
        libscript_symlink_alias 'busybox' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'busybox' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_busybox_url)
      if [ -z "$URL" ]; then
        libscript_depends 'busybox'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/busybox/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/busybox-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='busybox' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${BUSYBOX_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/busybox-windows/releases/download/v${EXACT_VERSION}/busybox-${EXACT_VERSION}-dos32.exe"
            TMP_FILE="${TMPDIR:-/tmp}/busybox-$$.exe"
            PACKAGE_NAME='busybox' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${BUSYBOX_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            _win_arch=$(resolve_win_arch)
            URL="https://github.com/SamuelMarks/busybox-windows/releases/download/v${EXACT_VERSION}/busybox-${EXACT_VERSION}-${_win_arch}.zip"
            TMP_FILE="${TMPDIR:-/tmp}/busybox-$$.zip"
            PACKAGE_NAME='busybox' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      case "$URL" in
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          for _cand in "$TARGET_DIR/busybox.exe" "$TARGET_DIR/BUSYBOX.EXE" "$TARGET_DIR/bin/busybox.exe"; do
            if [ -f "$_cand" ] && [ "$_cand" != "$TARGET_DIR/bin/${_bin_name}" ]; then
              cp -f "$_cand" "$TARGET_DIR/bin/${_bin_name}"
              break
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
      materialize_busybox_shims "${TARGET_DIR}" "${_bin_name}"
      libscript_symlink_alias 'busybox' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'busybox' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'busybox' "$ACTION" "$VERSION" "${BUSYBOX_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
