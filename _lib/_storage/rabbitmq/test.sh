#!/bin/sh
set -feu
DIR=$(CDPATH='' cd -- "$(dirname -- "${0}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/priv.sh"
if command -v rabbitmqctl >/dev/null 2>&1; then
  priv rabbitmqctl version
elif [ -x /usr/sbin/rabbitmqctl ]; then
  priv /usr/sbin/rabbitmqctl version
elif [ -x /opt/homebrew/sbin/rabbitmqctl ]; then
  priv /opt/homebrew/sbin/rabbitmqctl version
elif [ -x /usr/local/sbin/rabbitmqctl ]; then
  priv /usr/local/sbin/rabbitmqctl version
else
  echo "rabbitmqctl not found"
  exit 1
fi
