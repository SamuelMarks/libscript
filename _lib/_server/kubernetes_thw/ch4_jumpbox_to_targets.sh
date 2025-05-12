#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for lib in 'env.sh' '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md
depends openssl

if [ ! -f "${LIBSCRIPT_DATA_DIR}"'/ca.key' ]; then
  openssl genrsa -out "${LIBSCRIPT_DATA_DIR}"'/ca.key' 4096
  openssl req -x509 -new -sha512 -noenc \
    -key "${LIBSCRIPT_DATA_DIR}"'/ca.key' -days 3653 \
    -config "${LIBSCRIPT_DATA_DIR}"'/ca.conf' \
    -out "${LIBSCRIPT_DATA_DIR}"'/ca.crt'
fi

for i in 'node0' 'node1' 'node2' 'node3' 'admin' 'kube-proxy' 'kube-scheduler' 'kube-controller-manager' 'kube-api-server' 'service-accounts'; do
  key="${LIBSCRIPT_DATA_DIR}"'/'"${i}"'.key'
  if [ ! -f "${key}" ]; then
    openssl genrsa -out "${key}" 4096

    openssl req -new -key "${key}" -sha256 \
      -config "${LIBSCRIPT_DATA_DIR}"'/ca.conf' -section ${i} \
      -out "${LIBSCRIPT_DATA_DIR}"'/'"${i}"'.csr'

    openssl x509 -req -days 3653 -in "${LIBSCRIPT_DATA_DIR}"'/'"${i}"'.csr' \
      -copy_extensions copyall \
      -sha256 -CA "${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
      -CAkey "${LIBSCRIPT_DATA_DIR}"'/ca.key' \
      -CAcreateserial \
      -out "${LIBSCRIPT_DATA_DIR}"'/'"${i}"'.crt'
  fi
done

scp \
  "${LIBSCRIPT_DATA_DIR}"'/ca.key' "${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
  "${LIBSCRIPT_DATA_DIR}"'/kube-api-server.key' "${LIBSCRIPT_DATA_DIR}"'/kube-api-server.crt' \
  "${LIBSCRIPT_DATA_DIR}"'/service-accounts.key' "${LIBSCRIPT_DATA_DIR}"'/service-accounts.crt' \
  root@server:~/
