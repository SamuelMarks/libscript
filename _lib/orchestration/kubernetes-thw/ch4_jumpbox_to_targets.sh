#!/bin/sh
# ## Overview
# Automates Chapter 4 (Certificate Authority) of Kubernetes the Hard Way.
#
# ## Usage
# Generates PKI infrastructure (CA and client/server certificates) and scp's them to the target nodes.

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


libscript_depends openssl

MACHINES_TXT="${MACHINES_TXT:-${DIR}/kubernetes-the-hard-way/machines.txt}"
if [ ! -f "${MACHINES_TXT}" ]; then
  printf 'Error: %s not found\n' "${MACHINES_TXT}" >&2
  exit 1
fi
NODES=$(awk '$3 ~ /^node-/ {print $3}' "${MACHINES_TXT}" || echo "node-0 node-1")
CA_CONF="${DIR}/kubernetes-the-hard-way/ca.conf"

if [ ! -f "${CA_CONF}" ]; then
  printf 'Error: %s not found\n' "${CA_CONF}" >&2
  exit 1
fi

for i in $NODES; do
  if ! grep -q "\\[${i}\\]" "${CA_CONF}"; then
    cat <<EOF >> "${CA_CONF}.tmp"

[${i}]
distinguished_name = ${i}_distinguished_name
prompt             = no
req_extensions     = ${i}_req_extensions

[${i}_req_extensions]
basicConstraints     = CA:FALSE
extendedKeyUsage     = clientAuth, serverAuth
keyUsage             = critical, digitalSignature, keyEncipherment
nsCertType           = client
nsComment            = "${i} Certificate"
subjectAltName       = DNS:${i}, IP:127.0.0.1
subjectKeyIdentifier = hash

[${i}_distinguished_name]
CN = system:node:${i}
O  = system:nodes
C  = US
ST = Washington
L  = Seattle
EOF
    cat "${CA_CONF}.tmp" >> "${CA_CONF}"
    rm -f "${CA_CONF}.tmp"
  fi
done

if [ ! -f "${LIBSCRIPT_DATA_DIR}/ca.key" ]; then
  openssl genrsa -out "${LIBSCRIPT_DATA_DIR}/ca.key" 4096
  openssl req -x509 -new -sha512 -noenc -key "${LIBSCRIPT_DATA_DIR}/ca.key" -days 3653 -config "${CA_CONF}" -out "${LIBSCRIPT_DATA_DIR}/ca.crt"
fi

for i in $NODES 'admin' 'kube-proxy' 'kube-scheduler' 'kube-controller-manager' 'kube-api-server' 'service-accounts'; do
  key="${LIBSCRIPT_DATA_DIR}/${i}.key"
  if [ ! -f "${key}" ]; then
    openssl genrsa -out "${key}" 4096
    openssl req -new -key "${key}" -sha256 -config "${CA_CONF}" -section "${i}" -out "${LIBSCRIPT_DATA_DIR}/${i}.csr"
    openssl x509 -req -days 3653 -in "${LIBSCRIPT_DATA_DIR}/${i}.csr" -copy_extensions copyall -sha256 -CA "${LIBSCRIPT_DATA_DIR}/ca.crt" -CAkey "${LIBSCRIPT_DATA_DIR}/ca.key" -CAcreateserial -out "${LIBSCRIPT_DATA_DIR}/${i}.crt"
  fi
done

scp "${LIBSCRIPT_DATA_DIR}/ca.key" "${LIBSCRIPT_DATA_DIR}/ca.crt" "${LIBSCRIPT_DATA_DIR}/kube-api-server.key" "${LIBSCRIPT_DATA_DIR}/kube-api-server.crt" "${LIBSCRIPT_DATA_DIR}/service-accounts.key" "${LIBSCRIPT_DATA_DIR}/service-accounts.crt" root@server:~/

for i in $NODES; do
  scp "${LIBSCRIPT_DATA_DIR}/ca.crt" "${LIBSCRIPT_DATA_DIR}/${i}.key" "${LIBSCRIPT_DATA_DIR}/${i}.crt" "root@${i}:~/"
done
