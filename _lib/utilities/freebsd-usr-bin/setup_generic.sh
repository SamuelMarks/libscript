#!/bin/sh
# ## Overview
# Generic setup script for the freebsd-usr-bin component supporting MS-DOS (dos32), Windows native (MSVC), and FreeBSD/POSIX builds, including both full-suite and single-applet (`FREEBSD_USR_BIN_APPLET`) resolution.
#
# ## Usage
# Invoked internally by the freebsd-usr-bin component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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

FREEBSD_USR_BIN_INSTALL_METHOD="${FREEBSD_USR_BIN_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${FREEBSD_USR_BIN_VERSION:-latest}"
APPLET="${FREEBSD_USR_BIN_APPLET:-}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/freebsd-usr-bin-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact freebsd-usr-bin version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    _rel_api="${FREEBSD_USR_BIN_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/freebsd-usr-bin-windows/releases/latest}"
    EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
    [ -z "$EXACT_VERSION" ] && EXACT_VERSION='15.0.0'
  else
    EXACT_VERSION="${VERSION#v}"
  fi
}

# ## resolve_default_fub_url
# Computes the target-specific download URL for full suite or single applet on MS-DOS and Windows.
resolve_default_fub_url() {
  if [ -n "${FREEBSD_USR_BIN_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${FREEBSD_USR_BIN_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    if [ -n "${APPLET}" ]; then
      printf 'https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v%s/%s-%s-dos32.zip\n' "${EXACT_VERSION}" "${APPLET}" "${EXACT_VERSION}"
    else
      printf 'https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v%s/freebsd-usr-bin-%s-dos32.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    fi
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    if [ -n "${APPLET}" ]; then
      printf 'https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v%s/%s-%s-windows.zip\n' "${EXACT_VERSION}" "${APPLET}" "${EXACT_VERSION}"
    else
      printf 'https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v%s/freebsd-usr-bin-%s-%s.zip\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    fi
    return 0
  fi
  printf '%s\n' ''
}

# ## stage_fub_payload
# Extracts a FreeBSD usr.bin suite or single-applet archive/binary into TARGET_DIR/bin.
stage_fub_payload() {
  _src_file="$1"
  _src_url="$2"
  _dst_dir="$3"
  mkdir -p "${_dst_dir}/bin"
  case "${_src_url}" in
    *.zip)
      unzip -q -o "${_src_file}" -d "${_dst_dir}"
      set +f
      for _exe in "${_dst_dir}"/*.exe "${_dst_dir}"/*.EXE; do
        [ -f "${_exe}" ] || continue
        _base=$(basename "${_exe}" | tr '[:upper:]' '[:lower:]')
        cp -f "${_exe}" "${_dst_dir}/bin/${_base}"
      done
      set -f
      for _ext in 'DOS32A.EXE' 'DOS4GW.EXE'; do
        if [ -f "${_dst_dir}/${_ext}" ]; then
          cp -f "${_dst_dir}/${_ext}" "${_dst_dir}/bin/${_ext}"
        fi
      done
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "${_src_file}" -C "${_dst_dir}" --strip-components=1 2>/dev/null || tar -xzf "${_src_file}" -C "${_dst_dir}"
      ;;
    *)
      _out_bin="${APPLET:-sed}"
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _out_bin="${_out_bin}.exe"
      fi
      cp -f "${_src_file}" "${_dst_dir}/bin/${_out_bin}"
      chmod +x "${_dst_dir}/bin/${_out_bin}" 2>/dev/null || true
      ;;
  esac
}

case "$ACTION" in
  ls)
    if [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'libscript_native' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freebsd-usr-bin" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freebsd-usr-bin"
    else
      if command -v sed >/dev/null 2>&1; then
        printf '%s\n' 'freebsd-usr-bin utilities available on PATH'
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${FREEBSD_USR_BIN_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/freebsd-usr-bin-windows/releases/latest}"
    printf '[ls-remote] Fetching available freebsd-usr-bin versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freebsd-usr-bin/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_fub_url)
    if [ -z "$URL" ]; then
      URL="https://github.com/SamuelMarks/freebsd-usr-bin-windows/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/freebsd-usr-bin"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading freebsd-usr-bin %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='freebsd-usr-bin' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      SRC_URL="${FREEBSD_USR_BIN_DOWNLOAD_URL:-https://github.com/SamuelMarks/freebsd-usr-bin-windows/archive/refs/tags/v${EXACT_VERSION}.tar.gz}"
      libscript_build_component_from_source 'freebsd-usr-bin' "$EXACT_VERSION" 'sed' 'c' 'cmake' "$SRC_URL"
      libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'freebsd-usr-bin'
    elif [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'nix' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'guix' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'spack' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'brew' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'winget' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'choco' ] || [ "${FREEBSD_USR_BIN_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${FREEBSD_USR_BIN_INSTALL_METHOD}" 'freebsd-usr-bin'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freebsd-usr-bin/${EXACT_VERSION}"
      _probe_bin="${APPLET:-sed}"
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _probe_bin="${_probe_bin}.exe"
      fi
      if [ -f "${TARGET_DIR}/bin/${_probe_bin}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] freebsd-usr-bin %s (%s) is already installed at %s.\n' "${EXACT_VERSION}" "${_probe_bin}" "${TARGET_DIR}"
        libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_fub_url)
      if [ -z "$URL" ]; then
        if [ "${TARGET_OS:-}" = 'freebsd' ]; then
          mkdir -p "${TARGET_DIR}/bin"
          for _sys_tool in sed grep cut tr sort uniq wc head tail xargs find cmp diff patch make tar unzip; do
            if [ -x "/usr/bin/${_sys_tool}" ]; then
              ln -sf "/usr/bin/${_sys_tool}" "${TARGET_DIR}/bin/${_sys_tool}"
            fi
          done
          libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
          libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
          exit 0
        fi
        SRC_URL="https://github.com/SamuelMarks/freebsd-usr-bin-windows/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
        libscript_build_component_from_source 'freebsd-usr-bin' "$EXACT_VERSION" 'sed' 'c' 'cmake' "$SRC_URL"
        libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/freebsd-usr-bin/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/freebsd-usr-bin-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='freebsd-usr-bin' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${FREEBSD_USR_BIN_DOWNLOAD_URL:-}" ] && [ -n "${APPLET}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v${EXACT_VERSION}/${APPLET}-${EXACT_VERSION}-dos32.exe"
            TMP_FILE="${TMPDIR:-/tmp}/freebsd-usr-bin-$$.exe"
            PACKAGE_NAME='freebsd-usr-bin' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${FREEBSD_USR_BIN_DOWNLOAD_URL:-}" ] && [ -n "${APPLET}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            _win_arch=$(resolve_win_arch)
            URL="https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v${EXACT_VERSION}/${APPLET}-${EXACT_VERSION}-${_win_arch}.exe"
            TMP_FILE="${TMPDIR:-/tmp}/freebsd-usr-bin-$$.exe"
            PACKAGE_NAME='freebsd-usr-bin' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      stage_fub_payload "$TMP_FILE" "$URL" "$TARGET_DIR"
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'freebsd-usr-bin' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'freebsd-usr-bin' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'freebsd-usr-bin' "$ACTION" "$VERSION" "${FREEBSD_USR_BIN_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
