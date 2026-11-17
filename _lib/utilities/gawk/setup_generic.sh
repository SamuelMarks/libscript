#!/bin/sh
# ## Overview
# Generic setup script for the gawk component supporting MS-DOS (dos32), Windows native (MSVC), and POSIX builds.
#
# ## Usage
# Invoked internally by the gawk component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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

GAWK_INSTALL_METHOD="${GAWK_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${GAWK_VERSION:-latest}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/gawk-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact gawk version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
      _rel_api="${GAWK_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/gawk-windows/releases/latest}"
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION='5.4.60'
    else
      EXACT_VERSION='5.3.1'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_default_gawk_url
# Computes the target-specific download URL for MS-DOS (dos32), Windows native (MSVC), or custom override.
resolve_default_gawk_url() {
  if [ -n "${GAWK_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${GAWK_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    printf 'https://github.com/SamuelMarks/gawk-windows/releases/download/v%s/gawk-%s-dos32.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    printf 'https://github.com/SamuelMarks/gawk-windows/releases/download/v%s/gawk-%s-%s.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    return 0
  fi
  printf '%s\n' ''
}

# ## stage_gawk_payload
# Extracts or copies a downloaded gawk archive or executable and ensures both gawk and awk shims exist.
stage_gawk_payload() {
  _src_file="$1"
  _src_url="$2"
  _dst_dir="$3"
  mkdir -p "${_dst_dir}/bin"
  if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
    case "${_src_url}" in
      *.zip)
        unzip -q -o "${_src_file}" -d "${_dst_dir}"
        for _cand in "${_dst_dir}/gawk.exe" "${_dst_dir}/GAWK.EXE" "${_dst_dir}/bin/gawk.exe" "${_dst_dir}/bin/GAWK.EXE"; do
          if [ -f "${_cand}" ] && [ "${_cand}" != "${_dst_dir}/bin/gawk.exe" ]; then
            cp -f "${_cand}" "${_dst_dir}/bin/gawk.exe"
            break
          fi
        done
        for _ext in 'DOS32A.EXE' 'DOS4GW.EXE' 'dos32a.exe' 'dos4gw.exe'; do
          if [ -f "${_dst_dir}/${_ext}" ] && [ ! -f "${_dst_dir}/bin/${_ext}" ]; then
            cp -f "${_dst_dir}/${_ext}" "${_dst_dir}/bin/${_ext}"
          fi
        done
        ;;
      *)
        cp -f "${_src_file}" "${_dst_dir}/bin/gawk.exe"
        ;;
    esac
    if [ -f "${_dst_dir}/bin/gawk.exe" ] && [ ! -f "${_dst_dir}/bin/awk.exe" ]; then
      cp -f "${_dst_dir}/bin/gawk.exe" "${_dst_dir}/bin/awk.exe"
    fi
  else
    case "${_src_url}" in
      *.tar.gz|*.tgz) tar -xzf "${_src_file}" -C "${_dst_dir}" --strip-components=1 2>/dev/null || tar -xzf "${_src_file}" -C "${_dst_dir}" ;;
      *.tar.xz|*.txz) tar -xJf "${_src_file}" -C "${_dst_dir}" --strip-components=1 2>/dev/null || tar -xJf "${_src_file}" -C "${_dst_dir}" ;;
      *.zip) unzip -q -o "${_src_file}" -d "${_dst_dir}" ;;
      *) cp -f "${_src_file}" "${_dst_dir}/bin/gawk" ;;
    esac
    if [ -f "${_dst_dir}/bin/gawk" ]; then
      chmod +x "${_dst_dir}/bin/gawk"
      ln -sf 'gawk' "${_dst_dir}/bin/awk"
    fi
  fi
}

case "$ACTION" in
  ls)
    if [ "${GAWK_INSTALL_METHOD}" = 'libscript_native' ] || [ "${GAWK_INSTALL_METHOD}" = 'from-source' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gawk" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/gawk"
    else
      if command -v gawk >/dev/null 2>&1; then
        gawk --version | head -n 1 || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${GAWK_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/gawk-windows/releases/latest}"
    printf '[ls-remote] Fetching available gawk versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'gawk' "${EXACT_VERSION}")
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'gawk' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'gawk' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_gawk_url)
    if [ -z "$URL" ]; then
      URL="https://ftp.gnu.org/gnu/gawk/gawk-${EXACT_VERSION}.tar.xz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gawk"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading gawk %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='gawk' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${GAWK_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      SRC_URL="${GAWK_DOWNLOAD_URL:-https://ftp.gnu.org/gnu/gawk/gawk-${EXACT_VERSION}.tar.xz}"
      libscript_build_component_from_source 'gawk' "$EXACT_VERSION" 'gawk' 'c' 'autotools' "$SRC_URL"
      libscript_symlink_alias 'gawk' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'gawk' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${GAWK_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'gawk'
    elif [ "${GAWK_INSTALL_METHOD}" = 'nix' ] || [ "${GAWK_INSTALL_METHOD}" = 'guix' ] || [ "${GAWK_INSTALL_METHOD}" = 'spack' ] || [ "${GAWK_INSTALL_METHOD}" = 'brew' ] || [ "${GAWK_INSTALL_METHOD}" = 'winget' ] || [ "${GAWK_INSTALL_METHOD}" = 'choco' ] || [ "${GAWK_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${GAWK_INSTALL_METHOD}" 'gawk'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir 'gawk' "${EXACT_VERSION}")
      _expected_bin="${TARGET_DIR}/bin/gawk"
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _expected_bin="${TARGET_DIR}/bin/gawk.exe"
      fi
      if [ -f "${_expected_bin}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] gawk %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'gawk' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'gawk' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_gawk_url)
      if [ -z "$URL" ]; then
        SRC_URL="https://ftp.gnu.org/gnu/gawk/gawk-${EXACT_VERSION}.tar.xz"
        libscript_build_component_from_source 'gawk' "$EXACT_VERSION" 'gawk' 'c' 'autotools' "$SRC_URL"
        libscript_symlink_alias 'gawk' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'gawk' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/gawk/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/gawk-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='gawk' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${GAWK_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/gawk-windows/releases/download/v${EXACT_VERSION}/gawk-${EXACT_VERSION}-dos32.exe"
            TMP_FILE="${TMPDIR:-/tmp}/gawk-$$.exe"
            PACKAGE_NAME='gawk' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${GAWK_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            _win_arch=$(resolve_win_arch)
            URL="https://github.com/SamuelMarks/gawk-windows/releases/download/v${EXACT_VERSION}/gawk-${EXACT_VERSION}-${_win_arch}.exe"
            TMP_FILE="${TMPDIR:-/tmp}/gawk-$$.exe"
            PACKAGE_NAME='gawk' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      stage_gawk_payload "$TMP_FILE" "$URL" "$TARGET_DIR"
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'gawk' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'gawk' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'gawk' "$ACTION" "$VERSION" "${GAWK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
