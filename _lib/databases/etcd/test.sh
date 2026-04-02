#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

if command -v -- etcd >/dev/null 2>&1; then 
    etcd >/dev/null 2>&1 &
    sleep 2
  fi

if command -v -- etcdctl >/dev/null 2>&1; then
  etcdctl endpoint health
else
  /opt/etcd/etcdctl endpoint health
fi
