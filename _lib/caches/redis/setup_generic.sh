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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

REDIS_INSTALL_METHOD="${REDIS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
REDIS_VERSION="${REDIS_VERSION:-latest}"

if [ "${REDIS_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'redis'
else
  # "source" install
  if [ "${REDIS_VERSION}" = "latest" ]; then
    REDIS_VERSION="7.4.1"
  fi
  dl_url="https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/redis}"
  bin_dir="${PREFIX}/bin"
  mkdir -p "${bin_dir}"

  log_info "Downloading and compiling Redis from ${dl_url}..."
  libscript_download "${dl_url}" "/tmp/redis.tar.gz"

  if ! command -v make >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
    log_error "'make' and a C compiler ('cc'/'gcc'/'clang') are required for source installation."
    exit 1
  fi

  tar -xzf "/tmp/redis.tar.gz" -C "/tmp"
  cd "/tmp/redis-${REDIS_VERSION}"
  make
  make PREFIX="${PREFIX}" install
  cd -
  rm -rf "/tmp/redis.tar.gz" "/tmp/redis-${REDIS_VERSION}"

  log_success "Redis installed to ${bin_dir}/redis-server"
fi

CONF_DIR="${LIBSCRIPT_DATA_DIR}/redis"
mkdir -p "${CONF_DIR}"
if [ ! -f "${CONF_DIR}/redis.conf" ]; then
  echo "port ${REDIS_LISTEN_PORT:-6379}" > "${CONF_DIR}/redis.conf"
  echo "bind ${REDIS_LISTEN_ADDRESS:-127.0.0.1}" >> "${CONF_DIR}/redis.conf"
  echo "dir ${CONF_DIR}" >> "${CONF_DIR}/redis.conf"
  echo "appendonly yes" >> "${CONF_DIR}/redis.conf"
fi
