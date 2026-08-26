#!/bin/sh
# ## Overview
# Automates Chapter 7 (Bootstrapping etcd) of Kubernetes the Hard Way.
#
# ## Usage
# Installs and configures etcd on the controller node.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for LIB in "_lib/_common/environ.sh" "_lib/_common/pkg_mgr.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done


scp "${DIR}/kubernetes-the-hard-way/downloads/controller/etcd" "${DIR}/kubernetes-the-hard-way/downloads/client/etcdctl" "${DIR}/kubernetes-the-hard-way/units/etcd.service" root@server:~/
ssh root@server << 'EOF'
  set -eu
  mv -f etcd etcdctl /usr/local/bin/ || true
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp -f ca.crt kube-api-server.key kube-api-server.crt /etc/etcd/
  mkdir -p /etc/systemd/system/; mv -f etcd.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
  etcdctl member list || true
EOF
