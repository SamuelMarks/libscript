#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

MINIO_INSTALL_METHOD="${MINIO_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
MINIO_VERSION="${MINIO_VERSION:-latest}"

if [ "${MINIO_INSTALL_METHOD}" = 'system' ]; then
  depends 'minio'
else
  # "source" install (direct download of binary)
  TARGET_OS="${TARGET_OS:-linux}"
  TARGET_ARCH="${TARGET_ARCH:-amd64}"
  
  if [ "${TARGET_ARCH}" = "x86_64" ]; then TARGET_ARCH="amd64"; fi
  if [ "${TARGET_ARCH}" = "aarch64" ]; then TARGET_ARCH="arm64"; fi
  if [ "${TARGET_ARCH}" = "armv7l" ]; then TARGET_ARCH="arm"; fi
  
  # MinIO OS uses standard darwin/linux
  case "${TARGET_OS}" in
    macos*|darwin*) os_name="darwin" ;;
    linux*) os_name="linux" ;;
    *) echo "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
  esac
  
  if [ "${MINIO_VERSION}" = "latest" ]; then
    dl_url="https://dl.min.io/server/minio/release/${os_name}-${TARGET_ARCH}/minio"
  else
    dl_url="https://dl.min.io/server/minio/release/${os_name}-${TARGET_ARCH}/archive/minio.${MINIO_VERSION}"
  fi
  
  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/minio}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"
  
  echo "Downloading MinIO from ${dl_url}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "${bin_dir}/minio" "${dl_url}"
  else
    echo "[ERROR] curl is required but not found."
    exit 1
  fi
  
  chmod +x "${bin_dir}/minio"
  echo "MinIO installed to ${bin_dir}/minio"
fi
