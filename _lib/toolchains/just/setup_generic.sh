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

JUST_INSTALL_METHOD="${JUST_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
JUST_VERSION="${JUST_VERSION:-1.39.0}"
if [ "${JUST_VERSION}" = "latest" ]; then JUST_VERSION="1.39.0"; fi

if [ "${JUST_INSTALL_METHOD}" = 'system' ]; then
  depends 'just'
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
  
  echo "Downloading JUST from ${dl_url}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "/tmp/${tar_name}.tar.gz" "${dl_url}"
  else
    echo "[ERROR] curl is required but not found."
    exit 1
  fi
  
  tar -xzf "/tmp/${tar_name}.tar.gz" -C "${bin_dir}" just
  rm -rf "/tmp/${tar_name}.tar.gz"
  
  chmod +x "${bin_dir}/just"
  
  echo "JUST installed to ${bin_dir}/just"
fi
