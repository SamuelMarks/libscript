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

for LIB in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

JUST_INSTALL_METHOD="${JUST_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
JUST_VERSION="${JUST_VERSION:-1.39.0}"
if [ "${JUST_VERSION}" = "latest" ]; then JUST_VERSION="1.39.0"; fi

if [ "${JUST_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'just'
else
  TARGET_OS="${TARGET_OS:-linux}"
  TARGET_ARCH="${TARGET_ARCH:-amd64}"

  if [ "${TARGET_ARCH}" = "amd64" ]; then arch="x86_64"; else arch="${TARGET_ARCH}"; fi
  if [ "${TARGET_ARCH}" = "arm64" ]; then arch="aarch64"; fi

  case "${TARGET_OS}" in
    macos*|darwin*) os_name="apple-darwin" ;;
    linux*) os_name="unknown-linux-musl" ;;
    *) echo "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
  esac

  tar_name="just-${JUST_VERSION}-${arch}-${os_name}"
  dl_url="https://github.com/casey/just/releases/download/${JUST_VERSION}/${tar_name}.tar.gz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/just}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"

  log_info "Downloading JUST from ${dl_url}..."
  libscript_download "${dl_url}" "/tmp/${tar_name}.tar.gz"

  tar -xzf "/tmp/${tar_name}.tar.gz" -C "${bin_dir}" just
  rm -rf "/tmp/${tar_name}.tar.gz"

  chmod +x "${bin_dir}/just"

  log_info "JUST installed to ${bin_dir}/just"
fi
