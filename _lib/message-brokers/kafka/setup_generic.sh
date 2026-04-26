#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

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
  KAFKA_TARBALL=$(mktemp)
  libscript_download "${dl_url}" "${KAFKA_TARBALL}"

  tar -xzf "${KAFKA_TARBALL}" -C "${PREFIX}" --strip-components=1
  rm -f "${KAFKA_TARBALL}"

  echo "Kafka installed to ${PREFIX}"

  # Set up a basic KRaft config to avoid Zookeeper
  CONF_DIR="${LIBSCRIPT_DATA_DIR}/kafka"
  mkdir -p "${CONF_DIR}"
  if [ ! -f "${CONF_DIR}/server.properties" ]; then
    cp "${PREFIX}/config/kraft/server.properties" "${CONF_DIR}/"
    sed -i.bak "s|^log.dirs=.*|log.dirs=${CONF_DIR}/kraft-combined-logs|g" "${CONF_DIR}/server.properties" || true
  fi
fi
