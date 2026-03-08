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

KAFKA_INSTALL_METHOD="${KAFKA_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-source}}"
KAFKA_VERSION="${KAFKA_VERSION:-latest}"

if [ "${KAFKA_INSTALL_METHOD}" = 'system' ]; then
  depends 'kafka'
else
  if [ "${KAFKA_VERSION}" = "latest" ]; then
    KAFKA_VERSION="3.9.0"
  fi
  SCALA_VERSION="2.13"

  dl_url="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/kafka}"
  mkdir -p "${PREFIX}"

  echo "Downloading Kafka from ${dl_url}..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -f -o "/tmp/kafka.tgz" "${dl_url}"
  else
    echo "[ERROR] curl is required but not found."
    exit 1
  fi

  tar -xzf "/tmp/kafka.tgz" -C "${PREFIX}" --strip-components=1
  rm -f "/tmp/kafka.tgz"

  echo "Kafka installed to ${PREFIX}"

  # Set up a basic KRaft config to avoid Zookeeper
  CONF_DIR="${LIBSCRIPT_DATA_DIR}/kafka"
  mkdir -p "${CONF_DIR}"
  if [ ! -f "${CONF_DIR}/server.properties" ]; then
    cp "${PREFIX}/config/kraft/server.properties" "${CONF_DIR}/"
    sed -i.bak "s|^log.dirs=.*|log.dirs=${CONF_DIR}/kraft-combined-logs|g" "${CONF_DIR}/server.properties" || true
  fi
fi
