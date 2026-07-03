#!/bin/sh
# ## Overview
# Generic setup script for the aria2 component.
# It provides fallback installation logic and cross-platform installation steps
# when a more specific OS/distribution setup script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ARIA2_INSTALL_METHOD="${ARIA2_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"

if [ "${ARIA2_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'aria2'
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

  libscript_depends 'tar' 'bzip2' || true # optional dependency resolution if available

  previous_wd="$(pwd)"
  cd "${DOWNLOAD_DIR}"
  tar -xjf "${archive}"
  DIR_NAME="aria2-${ARIA2_VERSION}-linux-gnu-${ARCH_STR}-build1"
  priv install "${DIR_NAME}/aria2c" "/usr/local/bin/aria2c"
  cd "${previous_wd}"
fi
