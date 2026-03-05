#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu

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
