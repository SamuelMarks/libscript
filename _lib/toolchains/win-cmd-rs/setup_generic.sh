#!/bin/sh
# ## Overview
# Generic setup script for the win-cmd-rs component implementing the Version Manager Contract.
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

WIN_CMD_RS_INSTALL_METHOD="${WIN_CMD_RS_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}}"
ACTION="${ACTION:-install}"
VERSION="${WIN_CMD_RS_VERSION:-latest}"

# ## resolve_effective_os
# Determines the effective target or host operating system without being clobbered by triplets.sh.
resolve_effective_os() {
  if [ "${IS_MSDOS:-0}" = '1' ]; then
    printf '%s\n' 'msdos'
  elif [ -n "${LIBSCRIPT_TARGET_OS:-}" ]; then
    printf '%s\n' "${LIBSCRIPT_TARGET_OS}"
  elif [ -n "${UNAME_LOWER:-}" ]; then
    printf '%s\n' "${UNAME_LOWER}"
  else
    uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf '%s\n' 'linux'
  fi
}

# ## resolve_exact_version
# Resolves dynamic version aliases (latest, stable, lts) into an exact normalized upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'stable' ] || [ "${VERSION}" = 'lts' ]; then
    EXACT_VERSION=''
    _rel_url="${WIN_CMD_RS_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases/latest}"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && [ "${LIBSCRIPT_FORCE_OFFLINE:-0}" != '1' ]; then
      EXACT_VERSION=$(libscript_fetch_stdout "${_rel_url}" | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
    fi
    if [ -z "${EXACT_VERSION}" ]; then
      _wcr_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-rs"
      if [ -d "${_wcr_home}" ]; then
        for _cand in $(find "${_wcr_home}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true); do
          [ -d "${_cand}" ] || continue
          _bname=$(basename -- "${_cand}")
          case "${_bname}" in
            default|latest|stable|lts) continue ;;
            *)
              if [ -x "${_cand}/bin/wincheck" ] || [ -f "${_cand}/bin/wincheck.exe" ]; then
                EXACT_VERSION="${_bname#v}"
              fi
              ;;
          esac
        done
      fi
    fi
    if [ -z "${EXACT_VERSION}" ]; then
      _wcr_dl="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/win-cmd-rs"
      if [ -d "${_wcr_dl}" ]; then
        for _arc in $(find "${_wcr_dl}" -maxdepth 1 -type f 2>/dev/null || true); do
          _aname=$(basename -- "${_arc}")
          _aver=$(printf '%s\n' "${_aname}" | sed -n 's/^win-cmd-rs-v\([0-9][0-9.]*\)-.*/\1/p' | head -n 1 || true)
          if [ -n "${_aver}" ]; then
            EXACT_VERSION="${_aver}"
          fi
        done
      fi
    fi
    if [ -z "${EXACT_VERSION}" ]; then
      EXACT_VERSION='0.0.1'
    fi
  else
    EXACT_VERSION="${VERSION#v}"
  fi
  return 0
}

# ## resolve_platform_artifact
# Maps the target or host OS and CPU architecture to the upstream SamuelMarks/win-cmd-rs release archive URL.
resolve_platform_artifact() {
  _t_os=$(resolve_effective_os)
  _t_arch="${LIBSCRIPT_TARGET_ARCH:-${ARCH:-$(uname -m 2>/dev/null || printf 'x86_64')}}"

  _norm_arch='x86_64'
  case "${_t_arch}" in
    x86_64|amd64|AMD64|x64) _norm_arch='x86_64' ;;
    aarch64|arm64|ARM64) _norm_arch='aarch64' ;;
    i386|i486|i586|i686|x86|dos32) _norm_arch='i586' ;;
    *) _norm_arch="${_t_arch}" ;;
  esac

  _rust_target=''
  _arc_ext='tar.gz'
  case "${_t_os}" in
    freedos*|msdos*|dos*)
      _rust_target='i586-pc-msdosdjgpp'
      _arc_ext='zip'
      ;;
    windows*|mingw*|msys*|cygwin*|win32*|nt*)
      _arc_ext='zip'
      case "${_norm_arch}" in
        x86_64) _rust_target='x86_64-pc-windows-msvc' ;;
        aarch64) _rust_target='aarch64-pc-windows-msvc' ;;
        *) _rust_target='' ;;
      esac
      ;;
    linux*)
      _arc_ext='tar.gz'
      case "${_norm_arch}" in
        x86_64) _rust_target='x86_64-unknown-linux-musl' ;;
        aarch64) _rust_target='aarch64-unknown-linux-gnu' ;;
        *) _rust_target='' ;;
      esac
      ;;
    darwin*|macos*)
      _arc_ext='tar.gz'
      case "${_norm_arch}" in
        x86_64) _rust_target='x86_64-apple-darwin' ;;
        aarch64) _rust_target='aarch64-apple-darwin' ;;
        *) _rust_target='' ;;
      esac
      ;;
    *)
      _rust_target=''
      ;;
  esac

  if [ -n "${WIN_CMD_RS_DOWNLOAD_URL:-}" ]; then
    RESOLVED_URL=$(printf '%s\n' "${WIN_CMD_RS_DOWNLOAD_URL}" | sed \
      -e "s/{VERSION}/${EXACT_VERSION}/g" \
      -e "s/{RUST_TARGET}/${_rust_target}/g" \
      -e "s/{OS}/${_t_os}/g" \
      -e "s/{ARCH}/${_norm_arch}/g" \
      -e "s/{EXT}/${_arc_ext}/g")
    return 0
  fi

  if [ -z "${_rust_target}" ]; then
    RESOLVED_URL=''
    return 1
  fi

  RESOLVED_URL="https://github.com/SamuelMarks/win-cmd-rs/releases/download/v${EXACT_VERSION}/win-cmd-rs-v${EXACT_VERSION}-${_rust_target}.${_arc_ext}"
  return 0
}

# ## is_target_already_installed
# Returns 0 when both wincheck and wincmd binaries exist in the target installation directory.
is_target_already_installed() {
  _chk_dir="$1"
  _chk_os=$(resolve_effective_os)
  case "${_chk_os}" in
    freedos*|msdos*|dos*|windows*|mingw*|msys*|cygwin*)
      if { [ -f "${_chk_dir}/bin/wincheck.exe" ] || [ -f "${_chk_dir}/bin/WINCHECK.EXE" ]; } && { [ -f "${_chk_dir}/bin/wincmd.exe" ] || [ -f "${_chk_dir}/bin/WINCMD.EXE" ]; }; then
        return 0
      fi
      return 1
      ;;
    *)
      if [ -x "${_chk_dir}/bin/wincheck" ] && [ -x "${_chk_dir}/bin/wincmd" ]; then
        return 0
      fi
      return 1
      ;;
  esac
}

# ## locate_staged_file
# Searches a staging directory case-insensitively for a named payload file and prints its path.
locate_staged_file() {
  _lsf_dir="$1"
  _lsf_name="$2"
  _lsf_upper=$(printf '%s\n' "${_lsf_name}" | tr '[:lower:]' '[:upper:]')
  for _lsf_cand in \
    "${_lsf_dir}/${_lsf_name}" \
    "${_lsf_dir}/${_lsf_upper}" \
    "${_lsf_dir}/bin/${_lsf_name}" \
    "${_lsf_dir}/bin/${_lsf_upper}"; do
    if [ -f "${_lsf_cand}" ]; then
      printf '%s\n' "${_lsf_cand}"
      return 0
    fi
  done
  _lsf_hit=$(find "${_lsf_dir}" -type f \( -name "${_lsf_name}" -o -name "${_lsf_upper}" \) 2>/dev/null | head -n 1 || true)
  if [ -n "${_lsf_hit}" ] && [ -f "${_lsf_hit}" ]; then
    printf '%s\n' "${_lsf_hit}"
    return 0
  fi
  return 1
}

# ## install_binaries_from_stage
# Copies extracted wincheck, wincmd, optional CWSDPMI.EXE, and license/doc files into TARGET_DIR.
install_binaries_from_stage() {
  _ibs_stage="$1"
  _ibs_target="$2"
  _ibs_os=$(resolve_effective_os)
  mkdir -p "${_ibs_target}/bin"

  case "${_ibs_os}" in
    freedos*|msdos*|dos*)
      _wc_exe=$(locate_staged_file "${_ibs_stage}" 'wincheck.exe' || true)
      _wm_exe=$(locate_staged_file "${_ibs_stage}" 'wincmd.exe' || true)
      if [ -z "${_wc_exe}" ] || [ -z "${_wm_exe}" ]; then
        log_error "Failed to locate WINCHECK.EXE and WINCMD.EXE inside ${_ibs_stage}"
        return 1
      fi
      cp -f "${_wc_exe}" "${_ibs_target}/bin/WINCHECK.EXE"
      if [ ! -e "${_ibs_target}/bin/wincheck.exe" ]; then
        cp -f "${_wc_exe}" "${_ibs_target}/bin/wincheck.exe"
      fi
      cp -f "${_wm_exe}" "${_ibs_target}/bin/WINCMD.EXE"
      if [ ! -e "${_ibs_target}/bin/wincmd.exe" ]; then
        cp -f "${_wm_exe}" "${_ibs_target}/bin/wincmd.exe"
      fi
      _cwsdpmi=$(locate_staged_file "${_ibs_stage}" 'cwsdpmi.exe' || true)
      if [ -n "${_cwsdpmi}" ]; then
        cp -f "${_cwsdpmi}" "${_ibs_target}/bin/CWSDPMI.EXE"
      fi
      ;;
    windows*|mingw*|msys*|cygwin*)
      _wc_exe=$(locate_staged_file "${_ibs_stage}" 'wincheck.exe' || true)
      _wm_exe=$(locate_staged_file "${_ibs_stage}" 'wincmd.exe' || true)
      if [ -z "${_wc_exe}" ] || [ -z "${_wm_exe}" ]; then
        log_error "Failed to locate wincheck.exe and wincmd.exe inside ${_ibs_stage}"
        return 1
      fi
      cp -f "${_wc_exe}" "${_ibs_target}/bin/wincheck.exe"
      cp -f "${_wm_exe}" "${_ibs_target}/bin/wincmd.exe"
      ;;
    *)
      _wc_bin=$(locate_staged_file "${_ibs_stage}" 'wincheck' || true)
      _wm_bin=$(locate_staged_file "${_ibs_stage}" 'wincmd' || true)
      if [ -z "${_wc_bin}" ] || [ -z "${_wm_bin}" ]; then
        log_error "Failed to locate wincheck and wincmd binaries inside ${_ibs_stage}"
        return 1
      fi
      cp -f "${_wc_bin}" "${_ibs_target}/bin/wincheck"
      cp -f "${_wm_bin}" "${_ibs_target}/bin/wincmd"
      chmod +x "${_ibs_target}/bin/wincheck" "${_ibs_target}/bin/wincmd"
      ;;
  esac

  case "${_ibs_os}" in
    freedos*|msdos*|dos*) _doc_list='README.md USAGE.md' ;;
    *) _doc_list='README.md USAGE.md LICENSE-MIT LICENSE-APACHE' ;;
  esac
  for _doc in $_doc_list; do
    _doc_src=$(locate_staged_file "${_ibs_stage}" "${_doc}" || true)
    if [ -n "${_doc_src}" ]; then
      cp -f "${_doc_src}" "${_ibs_target}/${_doc}"
    fi
  done
  return 0
}

# ## install_from_source_cargo
# Compiles wincmd and wincheck from a local checkout or upstream source tarball using Cargo.
install_from_source_cargo() {
  _ifs_target="$1"
  mkdir -p "${_ifs_target}/bin"

  if ! command -v cargo >/dev/null 2>&1; then
    (
      unset SCRIPT_NAME || true
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust latest
    )
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/rust/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/rust/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}"
      unset SCRIPT_NAME || true
    fi
  fi

  _src_dir="${WIN_CMD_RS_REPO_DIR:-}"
  if [ -z "${_src_dir}" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/../win-cmd-rs/Cargo.toml" ]; then
    _src_dir="${LIBSCRIPT_ROOT_DIR}/../win-cmd-rs"
  fi

  _tmp_src=''
  if [ -z "${_src_dir}" ] || [ ! -f "${_src_dir}/Cargo.toml" ]; then
    _tmp_src=$(mktemp -d "${TMPDIR:-/tmp}/win-cmd-rs-src.XXXXXX")
    _src_tgz="${_tmp_src}/src.tar.gz"
    _src_url="https://github.com/SamuelMarks/win-cmd-rs/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
    mkdir -p "${_tmp_src}/tree"
    if PACKAGE_NAME='win-cmd-rs' libscript_download "${_src_url}" "${_src_tgz}" "${WIN_CMD_RS_CHECKSUM:-}"; then
      tar -xzf "${_src_tgz}" -C "${_tmp_src}/tree" --strip-components=1
    elif [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && [ "${LIBSCRIPT_FORCE_OFFLINE:-0}" != '1' ] && command -v git >/dev/null 2>&1; then
      log_info "Source archive download unavailable; cloning tag v${EXACT_VERSION} via git..."
      rm -rf "${_tmp_src}/tree"
      if ! git clone --depth 1 --branch "v${EXACT_VERSION}" 'https://github.com/SamuelMarks/win-cmd-rs.git' "${_tmp_src}/tree"; then
        rm -rf "${_tmp_src}"
        return 1
      fi
    else
      rm -rf "${_tmp_src}"
      return 1
    fi
    _src_dir="${_tmp_src}/tree"
  fi

  _cargo_tgt=$(mktemp -d "${TMPDIR:-/tmp}/win-cmd-rs-build.XXXXXX")
  CARGO_TARGET_DIR="${_cargo_tgt}" cargo build --release --bins --manifest-path "${_src_dir}/Cargo.toml"
  cp -f "${_cargo_tgt}/release/wincheck" "${_ifs_target}/bin/wincheck"
  cp -f "${_cargo_tgt}/release/wincmd" "${_ifs_target}/bin/wincmd"
  chmod +x "${_ifs_target}/bin/wincheck" "${_ifs_target}/bin/wincmd"
  rm -rf "${_cargo_tgt}"
  [ -n "${_tmp_src}" ] && rm -rf "${_tmp_src}"
  return 0
}

case "${ACTION}" in
  ls)
    if [ "${WIN_CMD_RS_INSTALL_METHOD}" = 'libscript_native' ] || [ "${WIN_CMD_RS_INSTALL_METHOD}" = 'from-source' ] || [ "${WIN_CMD_RS_INSTALL_METHOD}" = 'source' ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-rs" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-rs"
    else
      if command -v wincheck >/dev/null 2>&1; then
        wincheck --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${WIN_CMD_RS_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases}"
    case "${RELEASES_URL}" in
      */releases/latest) RELEASES_URL='https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases' ;;
    esac
    printf '[ls-remote] Fetching available win-cmd-rs versions from %s...\n' "${RELEASES_URL}"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && [ "${LIBSCRIPT_FORCE_OFFLINE:-0}" != '1' ]; then
      libscript_fetch_stdout "${RELEASES_URL}" | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sed 's/^v//' | head -n 30 || true
    fi
    ;;
  use)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'win-cmd-rs' "${EXACT_VERSION}")
    if ! is_target_already_installed "${TARGET_DIR}"; then
      printf 'Version %s not installed. Installing...\n' "${EXACT_VERSION}"
      (
        unset SCRIPT_NAME || true
        STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs "${EXACT_VERSION}"
      )
    fi
    libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
    libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    if ! resolve_platform_artifact; then
      RESOLVED_URL="https://github.com/SamuelMarks/win-cmd-rs/archive/refs/tags/v${EXACT_VERSION}.tar.gz"
    fi
    DL_DIR="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/win-cmd-rs"
    mkdir -p "${DL_DIR}"
    ARCHIVE_NAME=$(basename -- "${RESOLVED_URL}")
    if [ -s "${DL_DIR}/${ARCHIVE_NAME}" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      printf '[download] Cached win-cmd-rs archive already present at %s.\n' "${DL_DIR}/${ARCHIVE_NAME}"
    else
      printf '[download] Pre-downloading win-cmd-rs %s from %s to %s...\n' "${EXACT_VERSION}" "${RESOLVED_URL}" "${DL_DIR}/${ARCHIVE_NAME}"
      PACKAGE_NAME='win-cmd-rs' libscript_download "${RESOLVED_URL}" "${DL_DIR}/${ARCHIVE_NAME}" "${WIN_CMD_RS_CHECKSUM:-}"
    fi
    ;;
  install)
    case "${WIN_CMD_RS_INSTALL_METHOD}" in
      from-source|source|cargo)
        resolve_exact_version
        TARGET_DIR=$(libscript_get_version_dir 'win-cmd-rs' "${EXACT_VERSION}")
        if is_target_already_installed "${TARGET_DIR}" && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
          log_info "win-cmd-rs ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
          libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
          libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
          exit 0
        fi
        install_from_source_cargo "${TARGET_DIR}"
        libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
        libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
        exit 0
        ;;
      system)
        LIBSCRIPT_FORCE_SYSTEM_PKG_MGR=1 libscript_depends 'win-cmd-rs'
        ;;
      nix|guix|spack|brew|winget|choco|scoop)
        libscript_depends_via "${WIN_CMD_RS_INSTALL_METHOD}" 'win-cmd-rs'
        ;;
      *)
        resolve_exact_version
        TARGET_DIR=$(libscript_get_version_dir 'win-cmd-rs' "${EXACT_VERSION}")
        if is_target_already_installed "${TARGET_DIR}" && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
          printf '[INFO] win-cmd-rs %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
          libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
          libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
          exit 0
        fi

        if ! resolve_platform_artifact; then
          log_info "No prebuilt win-cmd-rs release archive for ${UNAME:-unknown}/${ARCH:-unknown}; compiling from source..."
          install_from_source_cargo "${TARGET_DIR}"
          libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
          libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
          exit 0
        fi

        mkdir -p "${TARGET_DIR}/bin"
        ARCHIVE_NAME=$(basename -- "${RESOLVED_URL}")
        CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/win-cmd-rs/${ARCHIVE_NAME}"
        TMP_FILE=''
        if [ -s "${CACHED_DL}" ]; then
          TMP_FILE="${CACHED_DL}"
        else
          TMP_FILE="${TMPDIR:-/tmp}/win-cmd-rs-$$-${ARCHIVE_NAME}"
          if ! PACKAGE_NAME='win-cmd-rs' libscript_download "${RESOLVED_URL}" "${TMP_FILE}" "${WIN_CMD_RS_CHECKSUM:-}"; then
            rm -f "${TMP_FILE}"
            if [ -z "${WIN_CMD_RS_DOWNLOAD_URL:-}" ] && { [ -n "${WIN_CMD_RS_REPO_DIR:-}" ] || [ -f "${LIBSCRIPT_ROOT_DIR}/../win-cmd-rs/Cargo.toml" ] || command -v cargo >/dev/null 2>&1; }; then
              log_info 'Prebuilt download unavailable; falling back to local/Cargo source build...'
              install_from_source_cargo "${TARGET_DIR}"
              libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
              libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
              exit 0
            fi
            log_error "Failed to download win-cmd-rs artifact from ${RESOLVED_URL}"
            exit 1
          fi
        fi

        STAGE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/win-cmd-rs-stage.XXXXXX")
        case "${RESOLVED_URL}" in
          *.tar.gz|*.tgz)
            tar -xzf "${TMP_FILE}" -C "${STAGE_DIR}"
            ;;
          *.zip)
            if command -v unzip >/dev/null 2>&1; then
              unzip -q -o "${TMP_FILE}" -d "${STAGE_DIR}"
            elif command -v bsdtar >/dev/null 2>&1; then
              bsdtar -xf "${TMP_FILE}" -C "${STAGE_DIR}"
            else
              tar -xf "${TMP_FILE}" -C "${STAGE_DIR}"
            fi
            ;;
          *)
            cp -f "${TMP_FILE}" "${STAGE_DIR}/wincheck"
            ;;
        esac

        install_binaries_from_stage "${STAGE_DIR}" "${TARGET_DIR}"
        rm -rf "${STAGE_DIR}"
        if [ "${TMP_FILE}" != "${CACHED_DL}" ]; then
          rm -f "${TMP_FILE}"
        fi

        libscript_symlink_alias 'win-cmd-rs' "${VERSION#v}" "${EXACT_VERSION}"
        libscript_symlink_alias 'win-cmd-rs' 'default' "${EXACT_VERSION}"
        ;;
    esac
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'win-cmd-rs' "${ACTION}" "${VERSION}" "${WIN_CMD_RS_INSTALL_METHOD}" '' '' '' "$@"
    ;;
esac
