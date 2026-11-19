#!/bin/sh
# ## Overview
# Generic setup script for the dash component backed by SamuelMarks/dash-windows on Windows/MS-DOS and source/system on POSIX.
#
# ## Usage
# Invoked internally by the dash component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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
unset SCRIPT_NAME || true

DASH_INSTALL_METHOD="${DASH_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${DASH_VERSION:-latest}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/dash-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact dash version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    _rel_api="${DASH_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/dash-windows/releases/latest}"
    EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
    [ -z "$EXACT_VERSION" ] && EXACT_VERSION='0.5.12'
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_default_dash_url
# Computes the target-specific download URL for MS-DOS (dos32), Windows native (MSVC), or custom override.
resolve_default_dash_url() {
  if [ -n "${DASH_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${DASH_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    printf 'https://github.com/SamuelMarks/dash-windows/releases/download/v%s/dash-%s-dos32.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    printf 'https://github.com/SamuelMarks/dash-windows/releases/download/v%s/dash-%s-%s.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    return 0
  fi
  printf '%s\n' ''
}

# ## stage_dash_payload
# Extracts or copies dash into TARGET_DIR/bin and ensures both dash and sh aliases exist.
stage_dash_payload() {
  _src_file="$1"
  _src_url="$2"
  _dst_dir="$3"
  mkdir -p "${_dst_dir}/bin"
  if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
    case "${_src_url}" in
      *.zip)
        unzip -q -o "${_src_file}" -d "${_dst_dir}"
        for _cand in "${_dst_dir}/dash.exe" "${_dst_dir}/DASH.EXE" "${_dst_dir}/bin/dash.exe" "${_dst_dir}/bin/DASH.EXE"; do
          if [ -f "${_cand}" ] && [ "${_cand}" != "${_dst_dir}/bin/dash.exe" ]; then
            cp -f "${_cand}" "${_dst_dir}/bin/dash.exe"
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
        cp -f "${_src_file}" "${_dst_dir}/bin/dash.exe"
        ;;
    esac
    if [ -f "${_dst_dir}/bin/dash.exe" ] && [ ! -f "${_dst_dir}/bin/sh.exe" ]; then
      cp -f "${_dst_dir}/bin/dash.exe" "${_dst_dir}/bin/sh.exe"
    fi
  else
    case "${_src_url}" in
      *.tar.gz|*.tgz) tar -xzf "${_src_file}" -C "${_dst_dir}" --strip-components=1 2>/dev/null || tar -xzf "${_src_file}" -C "${_dst_dir}" ;;
      *.zip) unzip -q -o "${_src_file}" -d "${_dst_dir}" ;;
      *) cp -f "${_src_file}" "${_dst_dir}/bin/dash" ;;
    esac
    if [ -f "${_dst_dir}/bin/dash" ]; then
      chmod +x "${_dst_dir}/bin/dash"
      ln -sf 'dash' "${_dst_dir}/bin/sh"
    fi
  fi
}

case "$ACTION" in
  ls)
    if [ "${DASH_INSTALL_METHOD}" = 'libscript_native' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dash" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/dash"
    else
      if command -v dash >/dev/null 2>&1; then
        printf '%s\n' 'dash installed via system'
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${DASH_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/dash-windows/releases/latest}"
    printf '[ls-remote] Fetching available dash versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'dash' "${EXACT_VERSION}")
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_dash_url)
    if [ -z "$URL" ]; then
      URL="http://gondor.apana.org.au/~herbert/dash/files/dash-${EXACT_VERSION}.tar.gz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/dash"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading dash %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='dash' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${DASH_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${IS_MSDOS:-0}" = '1' ]; then
        TARGET_DIR=$(libscript_get_version_dir 'dash' "${EXACT_VERSION}")
        mkdir -p "${TARGET_DIR}/bin"
        if ! "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-dash-dos --target=dos32 --out="${TARGET_DIR}/bin/dash.exe" >/dev/null 2>&1; then
          "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-dash-dos --target=host --out="${TARGET_DIR}/bin/dash.exe" >/dev/null
        fi
        cp -f "${TARGET_DIR}/bin/dash.exe" "${TARGET_DIR}/bin/sh.exe"
        libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      SRC_URL="${DASH_DOWNLOAD_URL:-http://gondor.apana.org.au/~herbert/dash/files/dash-${EXACT_VERSION}.tar.gz}"
      libscript_build_component_from_source 'dash' "$EXACT_VERSION" 'dash' 'c' 'autotools' "$SRC_URL"
      libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${DASH_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'dash'
    elif [ "${DASH_INSTALL_METHOD}" = 'nix' ] || [ "${DASH_INSTALL_METHOD}" = 'guix' ] || [ "${DASH_INSTALL_METHOD}" = 'spack' ] || [ "${DASH_INSTALL_METHOD}" = 'brew' ] || [ "${DASH_INSTALL_METHOD}" = 'winget' ] || [ "${DASH_INSTALL_METHOD}" = 'choco' ] || [ "${DASH_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${DASH_INSTALL_METHOD}" 'dash'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir 'dash' "${EXACT_VERSION}")
      _expected_bin="${TARGET_DIR}/bin/dash"
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _expected_bin="${TARGET_DIR}/bin/dash.exe"
      fi
      if [ -f "${_expected_bin}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] dash %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_dash_url)
      if [ -z "$URL" ]; then
        SRC_URL="http://gondor.apana.org.au/~herbert/dash/files/dash-${EXACT_VERSION}.tar.gz"
        libscript_build_component_from_source 'dash' "$EXACT_VERSION" 'dash' 'c' 'autotools' "$SRC_URL"
        libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/dash/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/dash-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='dash' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${DASH_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/dash-windows/releases/download/v${EXACT_VERSION}/dash-${EXACT_VERSION}-dos32.exe"
            TMP_FILE="${TMPDIR:-/tmp}/dash-$$.exe"
            PACKAGE_NAME='dash' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${DASH_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            URL="https://github.com/SamuelMarks/dash-windows/releases/download/v${EXACT_VERSION}/dash-windows-${EXACT_VERSION}-win64.zip"
            TMP_FILE="${TMPDIR:-/tmp}/dash-$$.zip"
            PACKAGE_NAME='dash' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      stage_dash_payload "$TMP_FILE" "$URL" "$TARGET_DIR"
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'dash' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'dash' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'dash' "$ACTION" "$VERSION" "${DASH_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
