#!/bin/sh
# ## Overview
# Automates Chapter 11 (Pod Network Routes) of Kubernetes the Hard Way.
#
# ## Usage
# Creates routes across the cluster to map Pod CIDR ranges to internal IP addresses.

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


MACHINES_TXT="${MACHINES_TXT:-${DIR}/kubernetes-the-hard-way/machines.txt}"
NODES=$(awk '$3 ~ /^node-/ {print $3}' "${MACHINES_TXT}" || echo "node-0 node-1")
for NODE in $NODES; do
  NODE_IP=$(awk -v n="$NODE" '$3==n {print $1}' "${MACHINES_TXT}")
  NODE_SUBNET=$(awk -v n="$NODE" '$3==n {print $4}' "${MACHINES_TXT}")
  # shellcheck disable=SC2029

  ssh root@server "ip route add ${NODE_SUBNET} via ${NODE_IP} || true"
  
  for OTHER_NODE in $NODES; do
    if [ "$NODE" != "$OTHER_NODE" ]; then
      OTHER_IP=$(awk -v n="$OTHER_NODE" '$3==n {print $1}' "${MACHINES_TXT}")
      OTHER_SUBNET=$(awk -v n="$OTHER_NODE" '$3==n {print $4}' "${MACHINES_TXT}")
        # shellcheck disable=SC2029

      ssh root@$NODE "ip route add ${OTHER_SUBNET} via ${OTHER_IP} || true"
    fi
  done
done
