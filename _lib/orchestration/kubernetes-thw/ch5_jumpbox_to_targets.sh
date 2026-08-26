#!/bin/sh
# ## Overview
# Automates Chapter 5 (Kubeconfig) of Kubernetes the Hard Way.
#
# ## Usage
# Generates kubeconfig files for workers, proxy, scheduler, and admin, then scp's them to targets.

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


MACHINES_TXT="${MACHINES_TXT:-${DIR}/kubernetes-the-hard-way/machines.txt}"
NODES=$(awk '$3 ~ /^node-/ {print $3}' "${MACHINES_TXT}" || echo "node-0 node-1")
SERVER_IP=$(awk '$3 == "server" {print $1}' "${MACHINES_TXT}" || echo "192.168.56.10")
for host in $NODES; do
  ssh root@"${host}" "mkdir -p -- /var/lib/kubelet/"
  scp "${LIBSCRIPT_DATA_DIR}/ca.crt" root@"${host}":/var/lib/kubelet/
  scp "${LIBSCRIPT_DATA_DIR}/${host}.crt" root@"${host}":/var/lib/kubelet/kubelet.crt
  scp "${LIBSCRIPT_DATA_DIR}/${host}.key" root@"${host}":/var/lib/kubelet/kubelet.key
done
libscript_depends kubectl

for host in $NODES; do
  kubectl config set-cluster 'kubernetes-the-hard-way' --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs='true' --server="https://${SERVER_IP}:6443" --kubeconfig="${LIBSCRIPT_DATA_DIR}/${host}.kubeconfig"
  kubectl config set-credentials "system:node:${host}" --client-certificate="${LIBSCRIPT_DATA_DIR}/${host}.crt" --client-key="${LIBSCRIPT_DATA_DIR}/${host}.key" --embed-certs='true' --kubeconfig="${LIBSCRIPT_DATA_DIR}/${host}.kubeconfig"
  kubectl config set-context 'default' --cluster='kubernetes-the-hard-way' --user="system:node:${host}" --kubeconfig="${LIBSCRIPT_DATA_DIR}/${host}.kubeconfig"
  kubectl config use-context 'default' --kubeconfig="${LIBSCRIPT_DATA_DIR}/${host}.kubeconfig"
done
libscript_depends kubectl

kubectl config set-cluster 'kubernetes-the-hard-way' --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs='true' --server="https://${SERVER_IP}:6443" --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-proxy.kubeconfig"
kubectl config set-credentials 'system:kube-proxy' --client-certificate="${LIBSCRIPT_DATA_DIR}/kube-proxy.crt" --client-key="${LIBSCRIPT_DATA_DIR}/kube-proxy.key" --embed-certs='true' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-proxy.kubeconfig"
kubectl config set-context 'default' --cluster='kubernetes-the-hard-way' --user='system:kube-proxy' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-proxy.kubeconfig"
kubectl config use-context 'default' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-proxy.kubeconfig"

kubectl config set-cluster 'kubernetes-the-hard-way' --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs='true' --server="https://${SERVER_IP}:6443" --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.kubeconfig"
kubectl config set-credentials 'system:kube-controller-manager' --client-certificate="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.crt" --client-key="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.key" --embed-certs='true' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.kubeconfig"
kubectl config set-context 'default' --cluster='kubernetes-the-hard-way' --user='system:kube-controller-manager' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.kubeconfig"
kubectl config use-context 'default' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-controller-manager.kubeconfig"

kubectl config set-cluster 'kubernetes-the-hard-way' --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs='true' --server="https://${SERVER_IP}:6443" --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-scheduler.kubeconfig"
kubectl config set-credentials 'system:kube-scheduler' --client-certificate="${LIBSCRIPT_DATA_DIR}/kube-scheduler.crt" --client-key="${LIBSCRIPT_DATA_DIR}/kube-scheduler.key" --embed-certs='true' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-scheduler.kubeconfig"
kubectl config set-context 'default' --cluster='kubernetes-the-hard-way' --user='system:kube-scheduler' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-scheduler.kubeconfig"
kubectl config use-context 'default' --kubeconfig="${LIBSCRIPT_DATA_DIR}/kube-scheduler.kubeconfig"

kubectl config set-cluster 'kubernetes-the-hard-way' --certificate-authority="${LIBSCRIPT_DATA_DIR}/ca.crt" --embed-certs='true' --server='https://127.0.0.1:6443' --kubeconfig="${LIBSCRIPT_DATA_DIR}/admin.kubeconfig"
kubectl config set-credentials 'admin' --client-certificate="${LIBSCRIPT_DATA_DIR}/admin.crt" --client-key="${LIBSCRIPT_DATA_DIR}/admin.key" --embed-certs='true' --kubeconfig="${LIBSCRIPT_DATA_DIR}/admin.kubeconfig"
kubectl config set-context 'default' --cluster='kubernetes-the-hard-way' --user='admin' --kubeconfig="${LIBSCRIPT_DATA_DIR}/admin.kubeconfig"
kubectl config use-context 'default' --kubeconfig="${LIBSCRIPT_DATA_DIR}/admin.kubeconfig"

for host in $NODES; do
  ssh root@"${host}" "mkdir -p -- /var/lib/kube-proxy /var/lib/kubelet"
  scp "${LIBSCRIPT_DATA_DIR}/kube-proxy.kubeconfig" root@"${host}":'/var/lib/kube-proxy/kubeconfig'
  scp "${LIBSCRIPT_DATA_DIR}/${host}.kubeconfig" root@"${host}":'/var/lib/kubelet/kubeconfig'
done
libscript_depends kubectl

scp "${LIBSCRIPT_DATA_DIR}/admin.kubeconfig" "${LIBSCRIPT_DATA_DIR}/kube-controller-manager.kubeconfig" "${LIBSCRIPT_DATA_DIR}/kube-scheduler.kubeconfig" root@server:~/
