#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

MINIO_INSTALL_METHOD="${MINIO_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
MINIO_VERSION="${MINIO_VERSION:-latest}"

if [ "${MINIO_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'minio'
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

  log_info "Downloading MinIO from ${dl_url}..."
  libscript_download "${dl_url}" "${bin_dir}/minio"

  chmod +x "${bin_dir}/minio"
  log_info "MinIO installed to ${bin_dir}/minio"
fi
