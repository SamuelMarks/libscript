#!/bin/sh

set -feu
if [ "${BASH_SOURCE-}" ] || [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi

if command -v -- etcdctl >/dev/null 2>&1; then
  etcdctl endpoint health
else
  /opt/etcd/etcdctl endpoint health
fi
