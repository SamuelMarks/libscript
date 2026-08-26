#!/bin/sh
# ## Overview
# Automates Chapter 10 (Configuring kubectl) of Kubernetes the Hard Way.
#
# ## Usage
# Generates a kubeconfig file for the kubectl command line utility.

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
libscript_depends kubectl


MACHINES_TXT="${DIR}/kubernetes-the-hard-way/machines.txt"
KUBERNETES_PUBLIC_ADDRESS=$(awk '/server/ {print $1}' "${MACHINES_TXT}")
# Use localhost to avoid timeout in QEMU isolated network
KUBERNETES_PUBLIC_ADDRESS="127.0.0.1"

PREVIOUS_WD="$(pwd)"
cd kubernetes-the-hard-way || exit 1
curl --cacert "${LIBSCRIPT_DATA_DIR}/ca.crt" "https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version" || true
kubectl config set-cluster kubernetes-the-hard-way --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs=true --server="https://${KUBERNETES_PUBLIC_ADDRESS}:6443"
kubectl config set-credentials admin --client-certificate="${LIBSCRIPT_DATA_DIR}/admin.crt" --client-key="${LIBSCRIPT_DATA_DIR}/admin.key"
kubectl config set-context kubernetes-the-hard-way --cluster=kubernetes-the-hard-way --user=admin
kubectl config use-context kubernetes-the-hard-way
kubectl version || true
kubectl get nodes || true
cd -- "${PREVIOUS_WD}"
