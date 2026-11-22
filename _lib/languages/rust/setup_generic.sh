#!/bin/sh
# ## Overview
# Generic setup module for Rust acting as an isolated side-by-side version manager
# (`rustup` replacement) with cross-compilation target and component management.
#
# ## Usage
# Invoked via `./libscript.sh <install|use|ls|ls-remote|target-add|target-rm|target-ls|component-add|component-ls|uninstall> rust [version] [args...]`.

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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "engine/common/pkg_mgr.sh" "engine/common/os_info.sh" "engine/common/versioning.sh"; do
  _rust_saved_this="${THIS_FILE}"
  _rust_saved_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_rust_saved_this}"
  SCRIPT_DIR="${_rust_saved_dir}"
  unset _rust_saved_this _rust_saved_dir || true
done

RUST_INSTALL_METHOD="${RUST_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript_native}}"
RUST_VERSION="${RUST_VERSION:-${VERSION:-stable}}"
if [ "${RUST_VERSION}" = "latest" ]; then
  RUST_VERSION='stable'
fi
ACTION="${ACTION:-install}"

# ## resolve_rust_host_triple
# Resolves the canonical Rust target triple for the current host OS and CPU architecture.
resolve_rust_host_triple() {
  _rht_os="${UNAME_LOWER:-linux}"
  _rht_arch="${ARCH:-x86_64}"
  case "$_rht_arch" in
    amd64|x86_64) _rht_arch='x86_64' ;;
    arm64|aarch64) _rht_arch='aarch64' ;;
  esac
  case "$_rht_os" in
    darwin*) printf '%s-apple-darwin\n' "$_rht_arch" ;;
    freebsd*) printf '%s-unknown-freebsd\n' "$_rht_arch" ;;
    linux*)
      if [ -f /etc/alpine-release ]; then
        printf '%s-unknown-linux-musl\n' "$_rht_arch"
      else
        printf '%s-unknown-linux-gnu\n' "$_rht_arch"
      fi
      ;;
    *) printf '%s-unknown-linux-gnu\n' "$_rht_arch" ;;
  esac
}

# ## resolve_exact_version
# Resolves Rust channels ('stable', 'beta', 'nightly', 'latest') or version strings to a concrete toolchain directory name.
resolve_exact_version() {
  if [ "${RUST_VERSION}" = "latest" ]; then
    EXACT_VERSION='stable'
  else
    EXACT_VERSION="${RUST_VERSION}"
  fi
}

# ## extract_rust_archive
# Installs a downloaded or cached Rust standalone installer/archive into a target prefix directory.
extract_rust_archive() {
  _era_archive="$1"
  _era_dest="$2"
  _era_tmp=$(mktemp -d)
  mkdir -p "${_era_dest}/bin" "${_era_dest}/lib/rustlib"
  tar -xf "${_era_archive}" -C "${_era_tmp}"
  _era_inner="${_era_tmp}"
  set +f
  for _era_sub in "${_era_tmp}"/*; do
    if [ -d "${_era_sub}" ]; then
      _era_inner="${_era_sub}"
      break
    fi
  done
  set -f
  if [ -f "${_era_inner}/install.sh" ]; then
    sh "${_era_inner}/install.sh" --prefix="${_era_dest}" --disable-ldconfig >/dev/null 2>&1 || sh "${_era_inner}/install.sh" --prefix="${_era_dest}" >/dev/null
  else
    if [ -d "${_era_inner}/bin" ]; then
      cp -R "${_era_inner}/bin/." "${_era_dest}/bin/"
    fi
    if [ -d "${_era_inner}/lib" ]; then
      cp -R "${_era_inner}/lib/." "${_era_dest}/lib/"
    fi
    set +f
    for _era_comp_sub in "${_era_inner}"/rustc "${_era_inner}"/cargo "${_era_inner}"/rust-std-* "${_era_inner}"/clippy* "${_era_inner}"/rustfmt*; do
      [ -d "${_era_comp_sub}" ] || continue
      [ -d "${_era_comp_sub}/bin" ] && cp -R "${_era_comp_sub}/bin/." "${_era_dest}/bin/"
      [ -d "${_era_comp_sub}/lib" ] && cp -R "${_era_comp_sub}/lib/." "${_era_dest}/lib/"
    done
    set -f
  fi
  rm -rf "${_era_tmp}"
}

# ## install_rust_target
# Idempotently installs a cross-compilation rust-std target into an installed toolchain directory.
install_rust_target() {
  _irt_ver="$1"
  _irt_target="$2"
  _irt_dir=$(libscript_get_version_dir "rust" "${_irt_ver}")
  if [ ! -d "${_irt_dir}/bin" ]; then
    log_error "Rust toolchain ${_irt_ver} is not installed at ${_irt_dir}. Install it first."
    exit 1
  fi
  _irt_tdir="${_irt_dir}/lib/rustlib/${_irt_target}"
  if [ -f "${_irt_tdir}/.libscript_target_stamp" ]; then
    log_info "[REUSE] Rust target ${_irt_target} already installed for ${_irt_ver}."
    return 0
  fi
  _irt_dl_dir="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rust"
  _irt_cached="${_irt_dl_dir}/rust-std-${_irt_ver}-${_irt_target}.tar.gz"
  mkdir -p "${_irt_tdir}"
  if [ -f "${_irt_cached}" ]; then
    extract_rust_archive "${_irt_cached}" "${_irt_dir}"
  else
    _irt_url="https://static.rust-lang.org/dist/rust-std-${_irt_ver}-${_irt_target}.tar.gz"
    mkdir -p "${_irt_dl_dir}"
    libscript_download "${_irt_url}" "${_irt_cached}"
    extract_rust_archive "${_irt_cached}" "${_irt_dir}"
  fi
  mkdir -p "${_irt_tdir}"
  printf '%s\n' "${_irt_target}" > "${_irt_tdir}/.libscript_target_stamp"
  log_info "Installed Rust target ${_irt_target} into ${_irt_dir}."
}

# ## install_rust_subcomponent
# Idempotently installs an optional Rust sub-component (e.g. clippy, rustfmt) into an installed toolchain directory.
install_rust_subcomponent() {
  _irc_ver="$1"
  _irc_comp="$2"
  _irc_triple=$(resolve_rust_host_triple)
  _irc_dir=$(libscript_get_version_dir "rust" "${_irc_ver}")
  if [ ! -d "${_irc_dir}/bin" ]; then
    log_error "Rust toolchain ${_irc_ver} is not installed at ${_irc_dir}. Install it first."
    exit 1
  fi
  _irc_reg="${_irc_dir}/.libscript_components"
  if [ -f "${_irc_reg}" ] && grep -qxF "${_irc_comp}" "${_irc_reg}" 2>/dev/null; then
    log_info "[REUSE] Rust component ${_irc_comp} already installed for ${_irc_ver}."
    return 0
  fi
  _irc_dl_dir="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rust"
  _irc_cached="${_irc_dl_dir}/${_irc_comp}-${_irc_ver}-${_irc_triple}.tar.gz"
  if [ ! -f "${_irc_cached}" ] && [ -f "${_irc_dl_dir}/${_irc_comp}-${_irc_ver}.tar.gz" ]; then
    _irc_cached="${_irc_dl_dir}/${_irc_comp}-${_irc_ver}.tar.gz"
  fi
  if [ -f "${_irc_cached}" ]; then
    extract_rust_archive "${_irc_cached}" "${_irc_dir}"
  else
    _irc_url="https://static.rust-lang.org/dist/${_irc_comp}-${_irc_ver}-${_irc_triple}.tar.gz"
    mkdir -p "${_irc_dl_dir}"
    libscript_download "${_irc_url}" "${_irc_cached}"
    extract_rust_archive "${_irc_cached}" "${_irc_dir}"
  fi
  printf '%s\n' "${_irc_comp}" >> "${_irc_reg}"
  if [ -L "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/default" ]; then
    _def_real=$(readlink "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/default" || true)
    if [ "${_def_real}" = "${_irc_ver}" ]; then
      libscript_sync_active_bin "rust"
    fi
  fi
  log_info "Installed Rust component ${_irc_comp} into ${_irc_dir}."
}

RUST_HOST_TRIPLE=$(resolve_rust_host_triple)

case "$ACTION" in
  ls)
    if [ "$RUST_INSTALL_METHOD" = "system" ]; then
      rustc --version 2>/dev/null || true
    else
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$RUST_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
      exit 0
    fi
    printf '%s\n' 'stable' 'beta' 'nightly'
    if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
      printf '%s\n' '1.85.0'
    elif [ -n "${RUST_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${RUST_RELEASES_URL}"
    elif command -v git >/dev/null 2>&1; then
      git ls-remote --tags "https://github.com/rust-lang/rust.git" 2>/dev/null | awk '{print $2}' | sed 's|refs/tags/||' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | libscript_sort_versions
    fi
    exit 0
    ;;
  use)
    if [ "$RUST_INSTALL_METHOD" = "system" ]; then
      log_error "Cannot 'use' specific version with system package manager."
      exit 1
    fi
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir "rust" "${EXACT_VERSION}")
    if [ ! -d "${TARGET_DIR}/bin" ]; then
      log_info "rust ${EXACT_VERSION} is not installed. Installing it now..."
      unset SCRIPT_NAME || true
      ACTION="install" RUST_VERSION="${EXACT_VERSION}" sh "${DIR}/setup.sh" install "rust" "${EXACT_VERSION}" || exit 1
    fi
    libscript_symlink_alias "rust" "${RUST_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "rust" "default" "${EXACT_VERSION}"
    log_info "Active rust toolchain set to ${EXACT_VERSION} (${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bin updated)."
    exit 0
    ;;
  download)
    resolve_exact_version
    _dl_dir="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rust"
    mkdir -p "${_dl_dir}"
    _dl_url="${RUST_DOWNLOAD_URL:-https://static.rust-lang.org/dist/rust-${EXACT_VERSION}-${RUST_HOST_TRIPLE}.tar.gz}"
    _dl_dest="${_dl_dir}/rust-${EXACT_VERSION}-${RUST_HOST_TRIPLE}.tar.gz"
    if [ -f "${_dl_dest}" ]; then
      log_info "[REUSE] Rust archive already cached at ${_dl_dest}."
      exit 0
    fi
    libscript_download "${_dl_url}" "${_dl_dest}"
    exit 0
    ;;
  target-add)
    resolve_exact_version
    if [ $# -eq 0 ] && [ -z "${RUST_TARGETS:-}" ]; then
      log_error 'Usage: libscript.sh target-add rust <version> <target-triple> [...]'
      exit 1
    fi
    for _t_arg in "$@"; do
      case "$_t_arg" in
        --*) ;;
        *) install_rust_target "${EXACT_VERSION}" "${_t_arg}" ;;
      esac
    done
    if [ -n "${RUST_TARGETS:-}" ]; then
      _oifs="$IFS"; IFS=','
      for _t_csv in $RUST_TARGETS; do
        [ -n "$_t_csv" ] && install_rust_target "${EXACT_VERSION}" "$_t_csv"
      done
      IFS="$_oifs"
    fi
    exit 0
    ;;
  target-rm)
    resolve_exact_version
    _trm_dir=$(libscript_get_version_dir "rust" "${EXACT_VERSION}")
    for _t_arg in "$@"; do
      case "$_t_arg" in
        --*) ;;
        *)
          rm -rf "${_trm_dir}/lib/rustlib/${_t_arg:?}"
          log_info "Removed Rust target ${_t_arg} from ${EXACT_VERSION}."
          ;;
      esac
    done
    exit 0
    ;;
  target-ls)
    resolve_exact_version
    _tls_dir="$(libscript_get_version_dir "rust" "${EXACT_VERSION}")/lib/rustlib"
    if [ -d "${_tls_dir}" ]; then
      set +f
      for _tls_entry in "${_tls_dir}"/*; do
        [ -d "${_tls_entry}" ] || continue
        _tls_name=$(basename -- "${_tls_entry}")
        case "${_tls_name}" in
          src|etc) ;;
          *) printf '%s\n' "${_tls_name}" ;;
        esac
      done
      set -f
    fi
    exit 0
    ;;
  component-add)
    resolve_exact_version
    if [ $# -eq 0 ] && [ -z "${RUST_COMPONENTS:-}" ]; then
      log_error 'Usage: libscript.sh component-add rust <version> <component> [...]'
      exit 1
    fi
    for _c_arg in "$@"; do
      case "$_c_arg" in
        --*) ;;
        *) install_rust_subcomponent "${EXACT_VERSION}" "${_c_arg}" ;;
      esac
    done
    exit 0
    ;;
  component-ls)
    resolve_exact_version
    _cls_reg="$(libscript_get_version_dir "rust" "${EXACT_VERSION}")/.libscript_components"
    if [ -f "${_cls_reg}" ]; then
      cat "${_cls_reg}"
    fi
    exit 0
    ;;
  install)
    if [ "$RUST_INSTALL_METHOD" = "system" ]; then
      depends 'rust'
    else
      resolve_exact_version
      TARGET_DIR=$(libscript_get_version_dir "rust" "${EXACT_VERSION}")
      if [ -x "${TARGET_DIR}/bin/rustc" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        log_info "[REUSE] rust ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      else
        _dl_dir="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/rust"
        _cached=''
        for _cand_arc in "${_dl_dir}/rust-${EXACT_VERSION}-${RUST_HOST_TRIPLE}.tar.gz" "${_dl_dir}/rust-${EXACT_VERSION}.tar.gz"; do
          if [ -f "${_cand_arc}" ]; then
            _cached="${_cand_arc}"
            break
          fi
        done
        if [ -z "${_cached}" ]; then
          mkdir -p "${_dl_dir}"
          _dl_url="${RUST_DOWNLOAD_URL:-https://static.rust-lang.org/dist/rust-${EXACT_VERSION}-${RUST_HOST_TRIPLE}.tar.gz}"
          _cached="${_dl_dir}/rust-${EXACT_VERSION}-${RUST_HOST_TRIPLE}.tar.gz"
          libscript_download "${_dl_url}" "${_cached}"
        fi
        extract_rust_archive "${_cached}" "${TARGET_DIR}"
        mkdir -p "${TARGET_DIR}/cargo/bin" "${TARGET_DIR}/rustup" "${TARGET_DIR}/lib/rustlib/${RUST_HOST_TRIPLE}"
        printf '%s\n' "${RUST_HOST_TRIPLE}" > "${TARGET_DIR}/lib/rustlib/${RUST_HOST_TRIPLE}/.libscript_target_stamp"
      fi

      if [ -n "${RUST_TARGETS:-${SUB_TARGETS:-}}" ]; then
        _oifs="$IFS"; IFS=','
        for _rust_tgt in ${RUST_TARGETS:-${SUB_TARGETS:-}}; do
          [ -n "$_rust_tgt" ] && install_rust_target "${EXACT_VERSION}" "$_rust_tgt"
        done
        IFS="$_oifs"
      fi
      if [ -n "${RUST_COMPONENTS:-${SUB_COMPONENTS:-}}" ]; then
        _oifs="$IFS"; IFS=','
        for _rcmp in ${RUST_COMPONENTS:-${SUB_COMPONENTS:-}}; do
          [ -n "$_rcmp" ] && install_rust_subcomponent "${EXACT_VERSION}" "$_rcmp"
        done
        IFS="$_oifs"
      fi

      libscript_symlink_alias "rust" "${RUST_VERSION}" "${EXACT_VERSION}"
      if [ "${LIBSCRIPT_AUTO_USE:-0}" = "1" ] || [ ! -e "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rust/default" ]; then
        libscript_symlink_alias "rust" "default" "${EXACT_VERSION}"
      fi
    fi
    exit 0
    ;;
  status|health|logs|uninstall)
    libscript_handle_generic_action "rust" "$ACTION" "${RUST_VERSION}" "${RUST_INSTALL_METHOD}" "" "" "" "$@"
    ;;
  *)
    log_error "Unsupported rust action: ${ACTION}"
    exit 1
    ;;
esac
