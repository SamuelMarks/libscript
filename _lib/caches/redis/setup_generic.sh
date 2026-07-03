#!/bin/sh
# ## Overview
# Provides the generic installation logic for Redis on Unix systems.
# It resolves the installation method (system package manager or building from source)
# and installs Redis accordingly. It also provisions default configuration files.
# 
# ## Usage
# Called internally by `setup.sh` when a platform-specific setup script is missing.


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
DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
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
  printf '%s\n' "port ${REDIS_LISTEN_PORT:-6379}" > "${CONF_DIR}/redis.conf"
  printf '%s\n' "bind ${REDIS_LISTEN_ADDRESS:-127.0.0.1}" >> "${CONF_DIR}/redis.conf"
  printf '%s\n' "dir ${CONF_DIR}" >> "${CONF_DIR}/redis.conf"
  printf '%s\n' "appendonly yes" >> "${CONF_DIR}/redis.conf"
fi
