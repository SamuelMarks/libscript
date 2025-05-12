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

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md
for host in node0 node1 node2; do
  ssh root@"${host}" mkdir /var/lib/kubelet/

  scp "${LIBSCRIPT_DATA_DIR}"'/ca.crt' root@"${host}":/var/lib/kubelet/

  scp "${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.crt' \
    root@"${host}":/var/lib/kubelet/kubelet.crt

  scp "${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.key' \
    root@"${host}":/var/lib/kubelet/kubelet.key
done

for host in node0 node1 node2; do
  kubectl config set-cluster 'kubernetes-the-hard-way' \
    --certificate-authority="${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
    --embed-certs='true' \
    --server='https://server.kubernetes.local:6443' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.kubeconfig'

  kubectl config set-credentials 'system:node:'"${host}" \
    --client-certificate="${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.crt' \
    --client-key="${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.key' \
    --embed-certs='true' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.kubeconfig'

  kubectl config set-context 'default' \
    --cluster='kubernetes-the-hard-way' \
    --user='system:node:'"${host}" \
    --kubeconfig="${host}"'.kubeconfig'

  kubectl config use-context 'default' \
    --kubeconfig="${host}"'.kubeconfig'
done

kubectl config set-cluster 'kubernetes-the-hard-way' \
    --certificate-authority="${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
    --embed-certs='true' \
    --server='https://server.kubernetes.local:6443' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.kubeconfig'

kubectl config set-credentials 'system:kube-proxy' \
    --client-certificate="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.crt' \
    --client-key="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.key' \
    --embed-certs='true' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.kubeconfig'

kubectl config set-context 'default' \
    --cluster='kubernetes-the-hard-way' \
    --user='system:kube-proxy' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.kubeconfig'

kubectl config use-context 'default' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-proxy.kubeconfig'

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-controller-manager-kubernetes-configuration-file

kubectl config set-cluster 'kubernetes-the-hard-way' \
    --certificate-authority="${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
    --embed-certs='true' \
    --server='https://server.kubernetes.local:6443' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.kubeconfig'

kubectl config set-credentials 'system:kube-controller-manager' \
    --client-certificate="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.crt' \
    --client-key="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.key' \
    --embed-certs='true' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.kubeconfig'

kubectl config set-context 'default' \
    --cluster='kubernetes-the-hard-way' \
    --user='system:kube-controller-manager' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.kubeconfig'

kubectl config use-context 'default' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.kubeconfig'

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-scheduler-kubernetes-configuration-file

kubectl config set-cluster 'kubernetes-the-hard-way' \
    --certificate-authority="${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
    --embed-certs='true' \
    --server='https://server.kubernetes.local:6443' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.kubeconfig'

kubectl config set-credentials 'system:kube-scheduler' \
    --client-certificate="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.crt' \
    --client-key="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.key' \
    --embed-certs='true' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.kubeconfig'

kubectl config set-context 'default' \
    --cluster='kubernetes-the-hard-way' \
    --user='system:kube-scheduler' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.kubeconfig'

kubectl config use-context 'default' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.kubeconfig'

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-admin-kubernetes-configuration-file

kubectl config set-cluster 'kubernetes-the-hard-way' \
    --certificate-authority="${LIBSCRIPT_DATA_DIR}"'/ca.crt' \
    --embed-certs='true' \
    --server='https://127.0.0.1:6443' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/admin.kubeconfig'

kubectl config set-credentials 'admin' \
    --client-certificate="${LIBSCRIPT_DATA_DIR}"'/admin.crt' \
    --client-key="${LIBSCRIPT_DATA_DIR}"'/admin.key' \
    --embed-certs='true' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/admin.kubeconfig'

kubectl config set-context 'default' \
    --cluster='kubernetes-the-hard-way' \
    --user='admin' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/admin.kubeconfig'

kubectl config use-context 'default' \
    --kubeconfig="${LIBSCRIPT_DATA_DIR}"'/admin.kubeconfig'

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#distribute-the-kubernetes-configuration-files

for host in node0 node1 node2; do
  ssh root@"${host}" "mkdir -p -- /var/lib/{kube-proxy,kubelet}"

  scp "${LIBSCRIPT_DATA_DIR}"'/kube-proxy.kubeconfig' \
    root@"${host}":'/var/lib/kube-proxy/kubeconfig'

  scp "${LIBSCRIPT_DATA_DIR}"'/'"${host}"'.kubeconfig' \
    root@"${host}":'/var/lib/kubelet/kubeconfig'
done

scp "${LIBSCRIPT_DATA_DIR}"'/admin.kubeconfig' \
  "${LIBSCRIPT_DATA_DIR}"'/kube-controller-manager.kubeconfig' \
  "${LIBSCRIPT_DATA_DIR}"'/kube-scheduler.kubeconfig' \
  root@server:~/
