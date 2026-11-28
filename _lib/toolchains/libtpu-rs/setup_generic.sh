#!/bin/sh
# ## Overview
# Generic setup script for `libtpu-rs` (`SamuelMarks/libtpu-rs`) supporting SHA-256 verified GitHub Releases with automatic Cargo + PEP 517 (`scripts/maturin_backend.py`) fallback under SIGPLAN `RULE-6` pinned release profiles.
#
# ## Usage
# Called internally by `_lib/toolchains/libtpu-rs/setup.sh`.

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

_ltr_sg_this="${THIS_FILE}"
_ltr_sg_dir="${SCRIPT_DIR}"
for _ltr_lib in 'engine/common/log.sh' 'engine/common/os_info.sh' 'engine/common/pkg_mgr.sh' 'engine/common/versioning.sh' 'engine/common/python_env.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ltr_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _ltr_lib || true
THIS_FILE="${_ltr_sg_this}"
SCRIPT_DIR="${_ltr_sg_dir}"

LIBTPU_RS_INSTALL_METHOD="${LIBTPU_RS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${LIBTPU_RS_VERSION:-0.0.52}"
LIBTPU_RS_RELEASES_URL="${LIBTPU_RS_RELEASES_URL:-https://api.github.com/repos/SamuelMarks/libtpu-rs/releases}"
LIBTPU_RS_GIT_URL="${LIBTPU_RS_GIT_URL:-https://github.com/SamuelMarks/libtpu-rs.git}"
LIBTPU_RS_CARGO_PROFILE="${LIBTPU_RS_CARGO_PROFILE:-opt3-lto-thin-cgu1}"
LIBTPU_RS_SLIM_FEATURES="${LIBTPU_RS_SLIM_FEATURES:---no-default-features}"
LIBTPU_RS_JAX_VERSION="${LIBTPU_RS_JAX_VERSION:-0.4.38}"

# ## write_pinned_cargo_profile
# Emits deterministic Cargo release profile metadata JSON and exports Cargo CARGO_PROFILE_RELEASE_* invariants.
write_pinned_cargo_profile() {
  _wcp_prof="$1"
  _wcp_out="$2"
  export CARGO_PROFILE_RELEASE_OPT_LEVEL='3'
  export CARGO_PROFILE_RELEASE_LTO='thin'
  export CARGO_PROFILE_RELEASE_CODEGEN_UNITS='1'
  printf '{"profile":"%s","opt_level":"3","lto":"thin","codegen_units":1}\n' "${_wcp_prof}" > "${_wcp_out}.tmp"
  mv -f "${_wcp_out}.tmp" "${_wcp_out}"
}

# ## strip_shared_lib_artifact
# Copies and strips debug symbols from a shared library when strip is available on PATH.
strip_shared_lib_artifact() {
  _ssl_src="$1"
  _ssl_dst="$2"
  cp -f "${_ssl_src}" "${_ssl_dst}.tmp"
  if command -v strip >/dev/null 2>&1; then
    strip -x "${_ssl_dst}.tmp" 2>/dev/null || strip --strip-unneeded "${_ssl_dst}.tmp" 2>/dev/null || true
  fi
  mv -f "${_ssl_dst}.tmp" "${_ssl_dst}"
}

# ## compute_file_sha256
# Computes the lowercase hexadecimal SHA-256 digest of a file using standard host utilities.
compute_file_sha256() {
  _cfs_file="${1}"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${_cfs_file}" | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${_cfs_file}" | awk '{print tolower($1)}'
  elif command -v sha256 >/dev/null 2>&1; then
    sha256 -q "${_cfs_file}" 2>/dev/null || sha256 "${_cfs_file}" | awk '{print tolower($NF)}'
  else
    openssl dgst -sha256 "${_cfs_file}" | awk '{print tolower($NF)}'
  fi
}

# ## resolve_exact_version
# Resolves dynamic version aliases for `libtpu-rs`.
resolve_exact_version() {
  if [ "${VERSION}" = 'latest' ] || [ "${VERSION}" = 'lts' ]; then
    EXACT_VERSION='0.0.52'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_release_platform_tag
# Maps host OS and ISA to SamuelMarks/libtpu-rs GitHub Release asset platform tags.
resolve_release_platform_tag() {
  if [ "${UNAME:-Linux}" = 'Darwin' ]; then
    printf 'macos-arm64\n'
  else
    case "${ARCH:-x86_64}" in
      aarch64|arm64) printf 'linux-aarch64\n' ;;
      *) printf 'linux-x86_64\n' ;;
    esac
  fi
}

# ## finalize_installed_libs
# Creates backward-compatible libtpu_c_api symlinks and persists SHA-256 and wheel path stamps.
finalize_installed_libs() {
  _fil_dir="$1"
  _fil_ext="$2"
  if [ -f "${_fil_dir}/lib/libtpu.${_fil_ext}" ]; then
    ln -sf "libtpu.${_fil_ext}" "${_fil_dir}/lib/libtpu_c_api.${_fil_ext}"
    _fil_sha=$(compute_file_sha256 "${_fil_dir}/lib/libtpu.${_fil_ext}")
    printf '%s\n' "${_fil_sha}" > "${_fil_dir}/lib/libtpu_so_sha256.txt.tmp"
    mv -f "${_fil_dir}/lib/libtpu_so_sha256.txt.tmp" "${_fil_dir}/lib/libtpu_so_sha256.txt"
  fi
  if [ -f "${_fil_dir}/lib/libtpu.unstripped.${_fil_ext}" ]; then
    ln -sf "libtpu.unstripped.${_fil_ext}" "${_fil_dir}/lib/libtpu_c_api.unstripped.${_fil_ext}"
  fi
  if [ -f "${_fil_dir}/lib/libtpu_slim.${_fil_ext}" ]; then
    ln -sf "libtpu_slim.${_fil_ext}" "${_fil_dir}/lib/libtpu_c_api_slim.${_fil_ext}"
  fi
  _whl_found=$(find "${_fil_dir}/wheels" -maxdepth 1 -type f -name '*.whl' 2>/dev/null | head -n 1 || true)
  if [ -n "${_whl_found}" ] && [ -f "${_whl_found}" ]; then
    printf '%s\n' "${_whl_found}" > "${_fil_dir}/wheels/wheel_path.txt.tmp"
    mv -f "${_fil_dir}/wheels/wheel_path.txt.tmp" "${_fil_dir}/wheels/wheel_path.txt"
  fi
}

# ## install_explicit_overrides
# Installs explicitly supplied LIBTPU_RS_SO_PATH / LIBTPU_RS_WHEEL_PATH overrides without network or Cargo builds.
install_explicit_overrides() {
  _ieo_dir="$1"
  _ieo_ext="$2"
  mkdir -p "${_ieo_dir}/lib" "${_ieo_dir}/wheels"
  cp -f "${LIBTPU_RS_SO_PATH}" "${_ieo_dir}/lib/libtpu.${_ieo_ext}.tmp"
  mv -f "${_ieo_dir}/lib/libtpu.${_ieo_ext}.tmp" "${_ieo_dir}/lib/libtpu.${_ieo_ext}"
  if [ -n "${LIBTPU_RS_SDK_SO_PATH:-}" ] && [ -f "${LIBTPU_RS_SDK_SO_PATH}" ]; then
    cp -f "${LIBTPU_RS_SDK_SO_PATH}" "${_ieo_dir}/lib/sdk.${_ieo_ext}.tmp"
    mv -f "${_ieo_dir}/lib/sdk.${_ieo_ext}.tmp" "${_ieo_dir}/lib/sdk.${_ieo_ext}"
  fi
  if [ -n "${LIBTPU_RS_WHEEL_PATH:-}" ] && [ -f "${LIBTPU_RS_WHEEL_PATH}" ]; then
    _whl_bn=$(basename -- "${LIBTPU_RS_WHEEL_PATH}")
    cp -f "${LIBTPU_RS_WHEEL_PATH}" "${_ieo_dir}/wheels/${_whl_bn}.tmp"
    mv -f "${_ieo_dir}/wheels/${_whl_bn}.tmp" "${_ieo_dir}/wheels/${_whl_bn}"
  fi
  finalize_installed_libs "${_ieo_dir}" "${_ieo_ext}"
}

# ## try_github_release_install
# Attempts to download and SHA-256 verify prebuilt GitHub Release archive + wheel assets, returning 1 on unavailability.
try_github_release_install() {
  _tgr_dir="$1"
  _tgr_ext="$2"
  if [ "${LIBSCRIPT_OFFLINE:-0}" = '1' ]; then
    return 1
  fi
  _plat=$(resolve_release_platform_tag)
  _dl_cache="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/libtpu-rs/${EXACT_VERSION}"
  mkdir -p "${_dl_cache}" "${_tgr_dir}/lib" "${_tgr_dir}/wheels"

  if [ -n "${LIBTPU_RS_DOWNLOAD_URL:-}" ]; then
    _arc_path="${_dl_cache}/libtpu-custom.tar.gz"
    if PACKAGE_NAME='libtpu-rs' libscript_download "${LIBTPU_RS_DOWNLOAD_URL}" "${_arc_path}" ''; then
      tar -xzf "${_arc_path}" -C "${_tgr_dir}/lib"
      finalize_installed_libs "${_tgr_dir}" "${_tgr_ext}"
      if [ -f "${_tgr_dir}/lib/libtpu.${_tgr_ext}" ]; then
        return 0
      fi
    fi
    return 1
  fi

  _rel_json="${_dl_cache}/releases.json"
  if ! libscript_fetch_stdout "${LIBTPU_RS_RELEASES_URL}" > "${_rel_json}.tmp" 2>/dev/null; then
    rm -f "${_rel_json}.tmp"
    return 1
  fi
  mv -f "${_rel_json}.tmp" "${_rel_json}"

  _tar_url=$(tr ',' '\n' < "${_rel_json}" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*'"${_plat}"'\.tar\.gz\)".*/\1/p' | head -n 1 || true)
  if [ -z "${_tar_url}" ]; then
    return 1
  fi
  _sums_url=$(tr ',' '\n' < "${_rel_json}" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*SHA256SUMS\.txt\)".*/\1/p' | head -n 1 || true)
  _tar_bn=$(basename -- "${_tar_url}")
  _tar_sha=''
  if [ -n "${_sums_url}" ]; then
    _sums_file="${_dl_cache}/SHA256SUMS.txt"
    if libscript_fetch_stdout "${_sums_url}" > "${_sums_file}.tmp" 2>/dev/null; then
      mv -f "${_sums_file}.tmp" "${_sums_file}"
      _tar_sha=$(awk -v fn="${_tar_bn}" '$2 == fn || $2 == ("*" fn) {print $1; exit}' "${_sums_file}")
    else
      rm -f "${_sums_file}.tmp"
    fi
  fi

  _tar_dst="${_dl_cache}/${_tar_bn}"
  if ! PACKAGE_NAME='libtpu-rs' libscript_download "${_tar_url}" "${_tar_dst}" "${_tar_sha}"; then
    return 1
  fi
  _unpack="${_dl_cache}/unpacked"
  rm -rf "${_unpack}"
  mkdir -p "${_unpack}"
  tar -xzf "${_tar_dst}" -C "${_unpack}"
  _found_so=$(find "${_unpack}" -type f \( -name "libtpu.${_tgr_ext}" -o -name "libtpu_c_api.${_tgr_ext}" \) 2>/dev/null | head -n 1 || true)
  if [ -z "${_found_so}" ]; then
    return 1
  fi
  cp -f "${_found_so}" "${_tgr_dir}/lib/libtpu.unstripped.${_tgr_ext}"
  strip_shared_lib_artifact "${_found_so}" "${_tgr_dir}/lib/libtpu.${_tgr_ext}"
  _found_sdk=$(find "${_unpack}" -type f -name "sdk*.${_tgr_ext}" 2>/dev/null | head -n 1 || true)
  if [ -n "${_found_sdk}" ]; then
    cp -f "${_found_sdk}" "${_tgr_dir}/lib/sdk.${_tgr_ext}"
  fi

  _whl_pat='manylinux.*x86_64'
  if [ "${_plat}" = 'linux-aarch64' ]; then
    _whl_pat='manylinux.*aarch64'
  elif [ "${_plat}" = 'macos-arm64' ]; then
    _whl_pat='macosx.*arm64'
  fi
  _whl_url=$(tr ',' '\n' < "${_rel_json}" | sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*'"${_whl_pat}"'[^"]*\.whl\)".*/\1/p' | head -n 1 || true)
  if [ -n "${_whl_url}" ]; then
    _whl_bn=$(basename -- "${_whl_url}")
    _whl_sha=''
    if [ -f "${_dl_cache}/SHA256SUMS.txt" ]; then
      _whl_sha=$(awk -v fn="${_whl_bn}" '$2 == fn || $2 == ("*" fn) {print $1; exit}' "${_dl_cache}/SHA256SUMS.txt")
    fi
    PACKAGE_NAME='libtpu-rs' libscript_download "${_whl_url}" "${_tgr_dir}/wheels/${_whl_bn}" "${_whl_sha}" || true
  fi

  finalize_installed_libs "${_tgr_dir}" "${_tgr_ext}"
  return 0
}

# ## resolve_repo_dir
# Resolves the local `libtpu-rs` source checkout or clones `LIBTPU_RS_GIT_URL` idempotently.
resolve_repo_dir() {
  if [ -n "${LIBTPU_RS_REPO_DIR:-}" ] && [ -d "${LIBTPU_RS_REPO_DIR}" ]; then
    (cd -- "${LIBTPU_RS_REPO_DIR}" && pwd)
    return 0
  fi
  if [ -d "${LIBSCRIPT_ROOT_DIR}/../libtpu-rs" ]; then
    (cd -- "${LIBSCRIPT_ROOT_DIR}/../libtpu-rs" && pwd)
    return 0
  fi
  if [ -n "${LIBTPU_RS_GIT_URL:-}" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
    _clone_dst="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache}/src/libtpu-rs"
    if [ ! -d "${_clone_dst}/.git" ]; then
      rm -rf "${_clone_dst}"
      mkdir -p "$(dirname -- "${_clone_dst}")"
      git clone --depth 1 "${LIBTPU_RS_GIT_URL}" "${_clone_dst}"
    fi
    printf '%s\n' "${_clone_dst}"
    return 0
  fi
  return 1
}

# ## build_from_cargo_source
# Compiles full and slim `libtpu` shared objects and PEP 517 drop-in Python wheel from Cargo source.
build_from_cargo_source() {
  _bcs_dir="$1"
  _bcs_ext="$2"
  mkdir -p "${_bcs_dir}/lib" "${_bcs_dir}/wheels"
  if ! _src_repo=$(resolve_repo_dir 2>/dev/null) || [ ! -f "${_src_repo}/Cargo.toml" ]; then
    log_warn 'No local libtpu-rs source checkout available for Cargo fallback build.'
    return 0
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust latest
  fi
  (
    cd -- "${_src_repo}"
    cargo build --release -p libtpu-c-api
  )
  _built_lib=''
  for _cand in "${_src_repo}/target/release/libtpu.${_bcs_ext}" "${_src_repo}/target/release/libtpu_c_api.${_bcs_ext}"; do
    if [ -f "${_cand}" ]; then
      _built_lib="${_cand}"
      break
    fi
  done
  if [ -n "${_built_lib}" ]; then
    cp -f "${_built_lib}" "${_bcs_dir}/lib/libtpu.unstripped.${_bcs_ext}"
    strip_shared_lib_artifact "${_built_lib}" "${_bcs_dir}/lib/libtpu.${_bcs_ext}"
  fi

  if [ -n "${LIBTPU_RS_SLIM_FEATURES}" ]; then
    (
      cd -- "${_src_repo}"
      # shellcheck disable=SC2086
      cargo build --release -p libtpu-c-api --target-dir "${_src_repo}/target/release-slim" ${LIBTPU_RS_SLIM_FEATURES} || true
    )
    for _scand in "${_src_repo}/target/release-slim/release/libtpu.${_bcs_ext}" "${_src_repo}/target/release-slim/release/libtpu_c_api.${_bcs_ext}"; do
      if [ -f "${_scand}" ]; then
        cp -f "${_scand}" "${_bcs_dir}/lib/libtpu_slim.unstripped.${_bcs_ext}"
        strip_shared_lib_artifact "${_scand}" "${_bcs_dir}/lib/libtpu_slim.${_bcs_ext}"
        break
      fi
    done
  fi

  if [ -f "${_src_repo}/pyproject.toml" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
    if command -v uv >/dev/null 2>&1; then
      (cd -- "${_src_repo}" && uv build --wheel --out-dir "${_bcs_dir}/wheels") || log_warn 'Optional PEP 517 libtpu-rs wheel build skipped.'
    fi
    _built_whl=$(find "${_bcs_dir}/wheels" -maxdepth 1 -type f -name '*.whl' 2>/dev/null | head -n 1 || true)
    if [ -n "${_built_whl}" ] && command -v unzip >/dev/null 2>&1; then
      _whl_tmp="${_bcs_dir}/wheels/.extract_sdk"
      rm -rf "${_whl_tmp}"
      mkdir -p "${_whl_tmp}"
      unzip -q -o "${_built_whl}" 'libtpu/sdk*' -d "${_whl_tmp}" 2>/dev/null || true
      _sdk_f=$(find "${_whl_tmp}" -type f -name 'sdk*' 2>/dev/null | head -n 1 || true)
      if [ -n "${_sdk_f}" ]; then
        cp -f "${_sdk_f}" "${_bcs_dir}/lib/sdk.${_bcs_ext}"
      fi
      rm -rf "${_whl_tmp}"
    fi
  fi

  finalize_installed_libs "${_bcs_dir}" "${_bcs_ext}"
}

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs"
    fi
    ;;
  ls-remote)
    if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
      libscript_fetch_stdout "${LIBTPU_RS_RELEASES_URL}" 2>/dev/null | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -n 10 || printf '0.0.52\n'
    else
      printf '0.0.52\n'
    fi
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      STACK='' ACTION='install' "${THIS_FILE}"
    fi
    libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
    _so_ext='so'
    if [ "${UNAME:-}" = 'Darwin' ]; then
      _so_ext='dylib'
    fi
    try_github_release_install "${TARGET_DIR}" "${_so_ext}" || resolve_repo_dir >/dev/null || true
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu-rs/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/libtpu-rs-env" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      printf '[INFO] libtpu-rs %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
      exit 0
    fi

    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/lib" "${TARGET_DIR}/wheels"
    write_pinned_cargo_profile "${LIBTPU_RS_CARGO_PROFILE}" "${TARGET_DIR}/cargo_profile.json"

    _so_ext='so'
    if [ "${UNAME:-}" = 'Darwin' ]; then
      _so_ext='dylib'
    fi

    if [ -n "${LIBTPU_RS_SO_PATH:-}" ] && [ -f "${LIBTPU_RS_SO_PATH}" ]; then
      install_explicit_overrides "${TARGET_DIR}" "${_so_ext}"
    elif [ "${LIBTPU_RS_INSTALL_METHOD}" = 'libscript_native' ] && [ -z "${LIBTPU_RS_REPO_DIR:-}" ]; then
      if ! try_github_release_install "${TARGET_DIR}" "${_so_ext}"; then
        log_info 'Prebuilt GitHub Release unavailable; falling back to Cargo source build for libtpu-rs.'
        build_from_cargo_source "${TARGET_DIR}" "${_so_ext}"
      fi
    else
      build_from_cargo_source "${TARGET_DIR}" "${_so_ext}"
    fi

    _req_file="${TARGET_DIR}/jax_requirements.txt"
    printf 'jax==%s\njaxlib==%s\n' "${LIBTPU_RS_JAX_VERSION}" "${LIBTPU_RS_JAX_VERSION}" > "${_req_file}"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && [ -z "${LIBTPU_RS_SO_PATH:-}" ]; then
      libscript_python_venv "${TARGET_DIR}/venv" '' "${_req_file}" || log_warn 'Deferred optional jax/jaxlib installation in venv.'
    fi

    cat <<INNER_EOF > "${TARGET_DIR}/bin/libtpu-rs-env.tmp"
#!/bin/sh
printf 'libtpu-rs %s (%s)\n' '${EXACT_VERSION}' '${TARGET_DIR}'
INNER_EOF
    mv -f "${TARGET_DIR}/bin/libtpu-rs-env.tmp" "${TARGET_DIR}/bin/libtpu-rs-env"
    chmod +x "${TARGET_DIR}/bin/libtpu-rs-env"
    libscript_symlink_alias 'libtpu-rs' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu-rs' 'default' "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'libtpu-rs' "$ACTION" "$VERSION" "${LIBTPU_RS_INSTALL_METHOD}" '' '' '' "$@"
    ;;
esac
