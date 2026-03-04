#!/bin/sh
set -feu
DIR=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}/ROOT" ]; do d="$(dirname -- "${d}")"; done; printf "%s" "${d}")}"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
depends etcd || echo "etcd installation skipped or failed"
