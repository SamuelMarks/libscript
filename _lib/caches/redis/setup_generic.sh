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

REDIS_INSTALL_METHOD="${REDIS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
REDIS_VERSION="${REDIS_VERSION:-latest}"

if [ "${REDIS_INSTALL_METHOD}" = 'system' ]; then
  depends 'redis'
else
  # "source" install
  if [ "${REDIS_VERSION}" = "latest" ]; then
    REDIS_VERSION="7.4.1"
  fi
  dl_url="https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/redis}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"

  echo "Downloading and compiling Redis from ${dl_url}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "/tmp/redis.tar.gz" "${dl_url}"
  else
    echo "[ERROR] curl is required but not found."
    exit 1
  fi

  if ! command -v make >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
    echo "[ERROR] 'make' and a C compiler ('cc'/'gcc'/'clang') are required for source installation."
    exit 1
  fi

  tar -xzf "/tmp/redis.tar.gz" -C "/tmp"
  cd "/tmp/redis-${REDIS_VERSION}"
  make
  make PREFIX="${PREFIX}" install
  cd -
  rm -rf "/tmp/redis.tar.gz" "/tmp/redis-${REDIS_VERSION}"

  echo "Redis installed to ${bin_dir}/redis-server"
fi

CONF_DIR="${LIBSCRIPT_DATA_DIR}/redis"
mkdir -p "${CONF_DIR}"
if [ ! -f "${CONF_DIR}/redis.conf" ]; then
  echo "port ${REDIS_LISTEN_PORT:-6379}" > "${CONF_DIR}/redis.conf"
  echo "bind ${REDIS_LISTEN_ADDRESS:-127.0.0.1}" >> "${CONF_DIR}/redis.conf"
  echo "dir ${CONF_DIR}" >> "${CONF_DIR}/redis.conf"
  echo "appendonly yes" >> "${CONF_DIR}/redis.conf"
fi
