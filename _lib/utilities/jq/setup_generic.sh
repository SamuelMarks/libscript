#!/bin/sh
# ## Overview
# Generic setup script for the jq component supporting MS-DOS (dos32), Windows native (MSVC), and POSIX binaries.
#
# ## Usage
# Invoked internally by the jq component lifecycle (`install`, `download`, `ls`, `ls-remote`, `use`, `uninstall`).

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

JQ_INSTALL_METHOD="${JQ_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${JQ_VERSION:-latest}"

# ## resolve_win_arch
# Maps LibScript ARCH values into SamuelMarks/jq-windows release asset architecture tokens.
resolve_win_arch() {
  case "${ARCH:-x86_64}" in
    aarch64|arm64|ARM64) printf '%s\n' 'ARM64' ;;
    i386|i686|x86|X86) printf '%s\n' 'X86' ;;
    *) printf '%s\n' 'X64' ;;
  esac
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact jq version for the active target OS.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
      _rel_api="${JQ_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/jq-windows/releases/latest}"
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//;s/^jq-//' || true)
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION='1.8.2'
    else
      _rel_api="${JQ_RELEASES_URL:-https://api.github.com/repos/jqlang/jq/releases/latest}"
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_api}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^jq-//;s/^v//' || true)
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION='1.7.1'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
    EXACT_VERSION="${EXACT_VERSION#jq-}"
  fi
}

# ## resolve_default_jq_url
# Computes the target-specific download URL for MS-DOS (dos32), Windows native (PE), or POSIX binaries.
resolve_default_jq_url() {
  if [ -n "${JQ_DOWNLOAD_URL:-}" ]; then
    printf '%s\n' "${JQ_DOWNLOAD_URL}" | sed -e "s/{VERSION}/${EXACT_VERSION}/g"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'msdos' ]; then
    printf 'https://github.com/SamuelMarks/jq-windows/releases/download/v%s/jq-%s-dos32.exe\n' "${EXACT_VERSION}" "${EXACT_VERSION}"
    return 0
  fi
  if [ "${TARGET_OS:-}" = 'windows' ]; then
    _win_arch=$(resolve_win_arch)
    printf 'https://github.com/SamuelMarks/jq-windows/releases/download/v%s/jq-%s-%s.exe\n' "${EXACT_VERSION}" "${EXACT_VERSION}" "${_win_arch}"
    return 0
  fi
  _jq_os='linux'
  case "${UNAME_LOWER:-linux}" in
    darwin*) _jq_os='macos' ;;
    linux*) _jq_os='linux' ;;
    *) printf '%s\n' ''; return 0 ;;
  esac
  _jq_arch='amd64'
  case "${ARCH:-x86_64}" in
    aarch64|arm64) _jq_arch='arm64' ;;
    i386|i686|x86) _jq_arch='i386' ;;
    *) _jq_arch='amd64' ;;
  esac
  printf 'https://github.com/jqlang/jq/releases/download/jq-%s/jq-%s-%s\n' "${EXACT_VERSION}" "${_jq_os}" "${_jq_arch}"
}

# ## stage_jq_payload
# Extracts or copies a downloaded jq archive or binary into TARGET_DIR/bin with target-appropriate naming.
stage_jq_payload() {
  _src_file="$1"
  _src_url="$2"
  _dst_dir="$3"
  mkdir -p "${_dst_dir}/bin"
  _bin_out='jq'
  if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
    _bin_out='jq.exe'
  fi
  case "${_src_url}" in
    *.zip)
      unzip -q -o "${_src_file}" -d "${_dst_dir}"
      for _cand in "${_dst_dir}/jq.exe" "${_dst_dir}/JQ.EXE" "${_dst_dir}/bin/jq.exe" "${_dst_dir}/bin/JQ.EXE"; do
        if [ -f "${_cand}" ] && [ "${_cand}" != "${_dst_dir}/bin/${_bin_out}" ]; then
          cp -f "${_cand}" "${_dst_dir}/bin/${_bin_out}"
          break
        fi
      done
      for _ext in 'DOS32A.EXE' 'DOS4GW.EXE' 'dos32a.exe' 'dos4gw.exe'; do
        if [ -f "${_dst_dir}/${_ext}" ] && [ ! -f "${_dst_dir}/bin/${_ext}" ]; then
          cp -f "${_dst_dir}/${_ext}" "${_dst_dir}/bin/${_ext}"
        fi
      done
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "${_src_file}" -C "${_dst_dir}" --strip-components=1 2>/dev/null || tar -xzf "${_src_file}" -C "${_dst_dir}"
      ;;
    *)
      cp -f "${_src_file}" "${_dst_dir}/bin/${_bin_out}"
      ;;
  esac
  if [ -f "${_dst_dir}/bin/${_bin_out}" ]; then
    chmod +x "${_dst_dir}/bin/${_bin_out}" 2>/dev/null || true
  fi
}

case "$ACTION" in
  ls)
    if [ "${JQ_INSTALL_METHOD}" = 'libscript_native' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/jq" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/jq"
    else
      if command -v jq >/dev/null 2>&1; then
        jq --version
      fi
    fi
    ;;
  ls-remote)
    if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
      RELEASES_URL="${JQ_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/jq-windows/releases/latest}"
    else
      RELEASES_URL="${JQ_RELEASES_URL:-https://api.github.com/repos/jqlang/jq/releases/latest}"
    fi
    printf '[ls-remote] Fetching available jq versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'jq' "${EXACT_VERSION}")
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      STACK='' ACTION='install' "${THIS_FILE}"
    fi
    libscript_symlink_alias 'jq' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'jq' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    URL=$(resolve_default_jq_url)
    if [ -z "$URL" ]; then
      printf '%s\n' 'No prebuilt jq URL resolved for current target.' >&2
      exit 1
    fi
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/jq"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading jq %s (%s) from %s to %s...\n' "$EXACT_VERSION" "${TARGET_OS:-host}" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    PACKAGE_NAME='jq' libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${JQ_INSTALL_METHOD}" = 'from-source' ]; then
      resolve_exact_version
      SRC_URL="${JQ_DOWNLOAD_URL:-https://github.com/jqlang/jq/releases/download/jq-${EXACT_VERSION}/jq-${EXACT_VERSION}.tar.gz}"
      libscript_build_component_from_source 'jq' "$EXACT_VERSION" 'jq' 'c' 'autotools' "$SRC_URL" '--with-oniguruma=builtin'
      libscript_symlink_alias 'jq' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'jq' 'default' "${EXACT_VERSION}"
      exit 0
    elif [ "${JQ_INSTALL_METHOD}" = 'system' ]; then
      libscript_depends 'jq'
    elif [ "${JQ_INSTALL_METHOD}" = 'nix' ] || [ "${JQ_INSTALL_METHOD}" = 'guix' ] || [ "${JQ_INSTALL_METHOD}" = 'spack' ] || [ "${JQ_INSTALL_METHOD}" = 'brew' ] || [ "${JQ_INSTALL_METHOD}" = 'winget' ] || [ "${JQ_INSTALL_METHOD}" = 'choco' ] || [ "${JQ_INSTALL_METHOD}" = 'scoop' ]; then
      libscript_depends_via "${JQ_INSTALL_METHOD}" 'jq'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir 'jq' "${EXACT_VERSION}")
      _expected_bin="${TARGET_DIR}/bin/jq"
      if [ "${TARGET_OS:-}" = 'msdos' ] || [ "${TARGET_OS:-}" = 'windows' ]; then
        _expected_bin="${TARGET_DIR}/bin/jq.exe"
      fi
      if [ -f "${_expected_bin}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
        printf '[INFO] jq %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'jq' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'jq' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      URL=$(resolve_default_jq_url)
      if [ -z "$URL" ]; then
        libscript_depends 'jq'
        exit 0
      fi
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/jq/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/jq-$$.${ARCHIVE_NAME}"
        if ! PACKAGE_NAME='jq' libscript_download "$URL" "$TMP_FILE"; then
          if [ -z "${JQ_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'msdos' ]; then
            URL="https://github.com/SamuelMarks/jq-windows/releases/download/v${EXACT_VERSION}/jq-${EXACT_VERSION}-dos32.zip"
            TMP_FILE="${TMPDIR:-/tmp}/jq-$$.zip"
            PACKAGE_NAME='jq' libscript_download "$URL" "$TMP_FILE"
          elif [ -z "${JQ_DOWNLOAD_URL:-}" ] && [ "${TARGET_OS:-}" = 'windows' ]; then
            _win_arch=$(resolve_win_arch)
            URL="https://github.com/SamuelMarks/jq-windows/releases/download/v${EXACT_VERSION}/jq-${EXACT_VERSION}-${_win_arch}.zip"
            TMP_FILE="${TMPDIR:-/tmp}/jq-$$.zip"
            PACKAGE_NAME='jq' libscript_download "$URL" "$TMP_FILE"
          else
            exit 1
          fi
        fi
      fi
      stage_jq_payload "$TMP_FILE" "$URL" "$TARGET_DIR"
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'jq' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'jq' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'jq' "$ACTION" "$VERSION" "${JQ_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
