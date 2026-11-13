#!/bin/sh
# ## Overview
# Generic setup script for the upstream reference `libtpu` component. Downloads and SHA-256 verifies official PyPI wheels (`manylinux_2_31_x86_64` and `manylinux_2_35_aarch64`) via `libscript_download` and extracts `libtpu/libtpu.so` and `libtpu/sdk.so`.
#
# ## Usage
# Called internally by `_lib/runtimes/libtpu/setup.sh`.

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

for _lt_lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/versioning.sh' '_lib/_common/experiment_harness.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_lt_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME _lt_lib || true

LIBTPU_INSTALL_METHOD="${LIBTPU_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${LIBTPU_VERSION:-0.0.52}"
LIBTPU_WHEEL_ARCH="${LIBTPU_WHEEL_ARCH:-both}"

# ## resolve_exact_version
# Resolves latest/lts aliases into the pinned reference PyPI release version (`0.0.52` fallback).
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    EXACT_VERSION='0.0.52'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## fetch_and_extract_wheel_arch
# Resolves wheel URL and SHA-256 from PyPI JSON metadata for a specific architecture (`x86_64` or `aarch64`), verifies via `libscript_download`, and extracts `libtpu.so` and `sdk.so`.
fetch_and_extract_wheel_arch() {
  _fwa_arch="${1}"
  _fwa_meta="${2}"
  _fwa_dest="${3}/${_fwa_arch}"
  mkdir -p "${_fwa_dest}"

  if [ -n "${LIBTPU_SO_PATH:-}" ] && [ -f "${LIBTPU_SO_PATH}" ]; then
    cp -f "${LIBTPU_SO_PATH}" "${_fwa_dest}/libtpu.so"
    if [ -n "${LIBTPU_SDK_SO_PATH:-}" ] && [ -f "${LIBTPU_SDK_SO_PATH}" ]; then
      cp -f "${LIBTPU_SDK_SO_PATH}" "${_fwa_dest}/sdk.so"
    fi
    return 0
  fi

  _fwa_info=$(awk -v arch="${_fwa_arch}" '
    BEGIN { RS="\\{"; FS="," }
    $0 ~ ("manylinux_[0-9]+_[0-9]+_" arch "\\.whl") {
      url=""; sha=""; fn=""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /"filename"[[:space:]]*:/) {
          fn = $i; sub(/^.*"filename"[[:space:]]*:[[:space:]]*"/, "", fn); sub(/".*$/, "", fn)
        }
        if ($i ~ /"url"[[:space:]]*:[[:space:]]*"https:/) {
          url = $i; sub(/^.*"url"[[:space:]]*:[[:space:]]*"/, "", url); sub(/".*$/, "", url)
        }
        if ($i ~ /"sha256"[[:space:]]*:/) {
          sha = $i; sub(/^.*"sha256"[[:space:]]*:[[:space:]]*"/, "", sha); sub(/".*$/, "", sha)
        }
      }
      if (url != "" && fn != "") {
        printf "%s|%s|%s\n", fn, url, sha
        exit
      }
    }
  ' "${_fwa_meta}")

  if [ -z "${_fwa_info}" ]; then
    log_warn "No PyPI wheel entry matched architecture '${_fwa_arch}' for libtpu ${EXACT_VERSION}."
    return 0
  fi

  _whl_fn="${_fwa_info%%|*}"
  _whl_rest="${_fwa_info#*|}"
  _whl_url="${_whl_rest%%|*}"
  _whl_sha="${_whl_rest#*|}"

  _dl_dir="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/libtpu"
  mkdir -p "${_dl_dir}"
  _whl_path="${_dl_dir}/${_whl_fn}"
  PACKAGE_NAME='libtpu' libscript_download "${_whl_url}" "${_whl_path}" "${_whl_sha}"

  if ! command -v unzip >/dev/null 2>&1; then
    libscript_depends 'unzip'
  fi
  unzip -Z1 "${_whl_path}" > "${_fwa_dest}/archive_members.txt"
  unzip -q -o "${_whl_path}" -d "${_fwa_dest}/extracted"
  if [ -f "${_fwa_dest}/extracted/libtpu/libtpu.so" ]; then
    ln -sf 'extracted/libtpu/libtpu.so' "${_fwa_dest}/libtpu.so"
  fi
  _sdk_cand=$(find "${_fwa_dest}/extracted/libtpu" -maxdepth 1 -type f -name 'sdk*.so' 2>/dev/null | head -n 1 || true)
  if [ -n "${_sdk_cand}" ] && [ -f "${_sdk_cand}" ]; then
    ln -sf "extracted/libtpu/$(basename -- "${_sdk_cand}")" "${_fwa_dest}/sdk.so"
  fi
  printf '%s\n' "${_whl_path}" > "${_fwa_dest}/wheel_path.txt"
  printf '%s\n' "${_whl_sha}" > "${_fwa_dest}/wheel_sha256.txt"
}

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu"
    fi
    ;;
  ls-remote)
    RELEASES_URL="${LIBTPU_RELEASES_URL:-https://pypi.org/pypi/libtpu/json}"
    libscript_fetch_stdout "${RELEASES_URL}" | tr ',' '\n' | grep '"version"' | head -n 10 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu/${EXACT_VERSION}"
    if [ ! -d "${TARGET_DIR}" ]; then
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'libtpu' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu' 'default' "${EXACT_VERSION}"
    ;;
  download|install)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/libtpu/${EXACT_VERSION}"
    if [ "${ACTION}" = "install" ] && [ -x "${TARGET_DIR}/bin/libtpu-info" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] libtpu %s is already installed at %s.\n' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'libtpu' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'libtpu' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin"
    _meta_json="${TARGET_DIR}/pypi_release_${EXACT_VERSION}.json"
    if [ -z "${LIBTPU_SO_PATH:-}" ] && [ ! -s "${_meta_json}" ]; then
      _pypi_url="https://pypi.org/pypi/libtpu/${EXACT_VERSION}/json"
      libscript_fetch_stdout "${_pypi_url}" > "${_meta_json}.tmp"
      mv -f "${_meta_json}.tmp" "${_meta_json}"
    else
      : > "${_meta_json}"
    fi
    case "${LIBTPU_WHEEL_ARCH}" in
      x86_64) fetch_and_extract_wheel_arch 'x86_64' "${_meta_json}" "${TARGET_DIR}" ;;
      aarch64|arm64) fetch_and_extract_wheel_arch 'aarch64' "${_meta_json}" "${TARGET_DIR}" ;;
      *)
        fetch_and_extract_wheel_arch 'x86_64' "${_meta_json}" "${TARGET_DIR}"
        fetch_and_extract_wheel_arch 'aarch64' "${_meta_json}" "${TARGET_DIR}"
        ;;
    esac
    cat <<EOF > "${TARGET_DIR}/bin/libtpu-info.tmp"
#!/bin/sh
printf 'libtpu-reference %s (%s)\n' '${EXACT_VERSION}' '${TARGET_DIR}'
EOF
    mv -f "${TARGET_DIR}/bin/libtpu-info.tmp" "${TARGET_DIR}/bin/libtpu-info"
    chmod +x "${TARGET_DIR}/bin/libtpu-info"
    libscript_symlink_alias 'libtpu' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'libtpu' 'default' "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'libtpu' "$ACTION" "$VERSION" "${LIBTPU_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
