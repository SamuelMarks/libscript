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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

ARIA2_INSTALL_METHOD="${ARIA2_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${ARIA2_INSTALL_METHOD}" = 'system' ]; then
  depends 'aria2'
else
  ARIA2_VERSION="${ARIA2_VERSION:-1.37.0}"
  if [ "${ARIA2_VERSION}" = "latest" ]; then
    ARIA2_VERSION="1.37.0"
  fi
  
  ARCH_STR="64bit"
  if [ "$(uname -m)" = "aarch64" ]; then
    ARCH_STR="aarch64"
  elif [ "$(uname -m)" = "armv7l" ]; then
    ARCH_STR="arm-rbpi"
  fi
  
  URL="https://github.com/q3aql/aria2-static-builds/releases/download/v${ARIA2_VERSION}/aria2-${ARIA2_VERSION}-linux-gnu-${ARCH_STR}-build1.tar.bz2"
  
  DOWNLOAD_DIR=${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}/aria2}
  mkdir -p "${DOWNLOAD_DIR}"
  archive="aria2.tar.bz2"
  libscript_download "$URL" "${DOWNLOAD_DIR}/${archive}" ""
  
  depends 'tar' 'bzip2' || true # optional dependency resolution if available
  
  previous_wd="$(pwd)"
  cd "${DOWNLOAD_DIR}"
  tar -xjf "${archive}"
  DIR_NAME="aria2-${ARIA2_VERSION}-linux-gnu-${ARCH_STR}-build1"
  priv install "${DIR_NAME}/aria2c" "/usr/local/bin/aria2c"
  cd "${previous_wd}"
fi
