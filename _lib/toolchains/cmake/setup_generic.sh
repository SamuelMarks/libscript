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

CMAKE_INSTALL_METHOD="${CMAKE_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
CMAKE_VERSION="${CMAKE_VERSION:-latest}"

if [ "${CMAKE_INSTALL_METHOD}" = 'system' ]; then
  depends 'cmake'
else
  # "source" install (direct download of binary)
  if [ "${CMAKE_VERSION}" = "latest" ]; then
    CMAKE_VERSION="3.31.2"
  fi

  TARGET_OS="${TARGET_OS:-linux}"
  TARGET_ARCH="${TARGET_ARCH:-amd64}"

  if [ "${TARGET_ARCH}" = "amd64" ] || [ "${TARGET_ARCH}" = "x86_64" ]; then arch="x86_64"; else arch="${TARGET_ARCH}"; fi
  if [ "${TARGET_ARCH}" = "arm64" ] || [ "${TARGET_ARCH}" = "aarch64" ]; then arch="aarch64"; fi

  case "${TARGET_OS}" in
    macos*|darwin*) 
      os_name="macos-universal"
      tar_name="cmake-${CMAKE_VERSION}-${os_name}"
      ;;
    linux*) 
      os_name="linux-${arch}" 
      tar_name="cmake-${CMAKE_VERSION}-${os_name}"
      ;;
    *) echo "[ERROR] Unsupported OS for direct download: ${TARGET_OS}"; exit 1 ;;
  esac

  dl_url="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${tar_name}.tar.gz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/cmake}"
  mkdir -p "${PREFIX}"

  echo "Downloading CMake from ${dl_url}..."
  libscript_download "${dl_url}" "/tmp/${tar_name}.tar.gz"

  tar -xzf "/tmp/${tar_name}.tar.gz" -C "/tmp"

  if echo "${TARGET_OS}" | grep -q "^darwin" || echo "${TARGET_OS}" | grep -q "^macos"; then
    cp -R "/tmp/${tar_name}/CMake.stacks/Contents/"* "${PREFIX}/"
  else
    cp -R "/tmp/${tar_name}/"* "${PREFIX}/"
  fi

  rm -rf "/tmp/${tar_name}.tar.gz" "/tmp/${tar_name}"

  echo "CMake installed to ${PREFIX}/bin/cmake"
fi
