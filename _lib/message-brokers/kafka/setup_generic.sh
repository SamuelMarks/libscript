#!/bin/sh
# ## Overview
# Generic setup module for Kafka.
#
# ## Usage
# Installs Kafka by downloading official releases from apache.org or via system package manager, and configures KRaft.


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

KAFKA_INSTALL_METHOD="${KAFKA_INSTALL_METHOD:-${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript-native}}"
KAFKA_VERSION="${KAFKA_VERSION:-latest}"

if [ "${KAFKA_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'kafka'
else
  if [ "${KAFKA_VERSION}" = "latest" ]; then
    KAFKA_VERSION="3.9.0"
  fi
  SCALA_VERSION="2.13"

  dl_url="https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"

  PREFIX="${PREFIX:-${LIBSCRIPT_ROOT_DIR}/installed/kafka}"
  mkdir -p "${PREFIX}"

  log_info "Downloading Kafka from ${dl_url}..."
  KAFKA_TARBALL=$(mktemp)
  libscript_download "${dl_url}" "${KAFKA_TARBALL}"

  tar -xzf "${KAFKA_TARBALL}" -C "${PREFIX}" --strip-components=1
  rm -f "${KAFKA_TARBALL}"

  log_info "Kafka installed to ${PREFIX}"

  # Set up a basic KRaft config to avoid Zookeeper
  CONF_DIR="${LIBSCRIPT_DATA_DIR}/kafka"
  mkdir -p "${CONF_DIR}"
  if [ ! -f "${CONF_DIR}/server.properties" ]; then
    cp "${PREFIX}/config/kraft/server.properties" "${CONF_DIR}/"
    sed -i.bak "s|^log.dirs=.*|log.dirs=${CONF_DIR}/kraft-combined-logs|g" "${CONF_DIR}/server.properties" || true
  fi
fi
