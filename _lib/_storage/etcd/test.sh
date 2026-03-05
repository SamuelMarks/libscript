#!/bin/sh

set -feu
if [ "${BASH_SOURCE-}" ] || [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC3040
  set -o pipefail
fi

if ! command -v nc >/dev/null 2>&1 || ! nc -z 127.0.0.1 2379; then
  if command -v -- etcd >/dev/null 2>&1; then 
    etcd >/dev/null 2>&1 &
    sleep 2
  fi
fi

if command -v -- etcdctl >/dev/null 2>&1; then
  etcdctl endpoint health
else
  /opt/etcd/etcdctl endpoint health
fi
