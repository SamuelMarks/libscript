#!/bin/sh
# ## Overview
# Automates Chapter 8 (Bootstrapping Kubernetes Controllers) of Kubernetes the Hard Way.
#
# ## Usage
# Installs and configures API server, controller manager, and scheduler on the controller node.

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


scp "${DIR}/kubernetes-the-hard-way/downloads/controller/kube-apiserver" "${DIR}/kubernetes-the-hard-way/downloads/controller/kube-controller-manager" "${DIR}/kubernetes-the-hard-way/downloads/controller/kube-scheduler" "${DIR}/kubernetes-the-hard-way/downloads/client/kubectl" "${DIR}/kubernetes-the-hard-way/units/kube-apiserver.service" "${DIR}/kubernetes-the-hard-way/units/kube-controller-manager.service" "${DIR}/kubernetes-the-hard-way/units/kube-scheduler.service" "${DIR}/kubernetes-the-hard-way/configs/kube-scheduler.yaml" "${DIR}/kubernetes-the-hard-way/configs/kube-apiserver-to-kubelet.yaml" root@server:~/

ssh root@server << 'EOF'
  set -eu
  mkdir -p /etc/kubernetes/config /var/lib/kubernetes/
  mv -f kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/ || true
  cp -f ca.crt ca.key kube-api-server.key kube-api-server.crt service-accounts.key service-accounts.crt encryption-config.yaml /var/lib/kubernetes/
  mkdir -p /etc/systemd/system/; mv -f kube-apiserver.service /etc/systemd/system/kube-apiserver.service || true
  cp -f kube-controller-manager.kubeconfig /var/lib/kubernetes/ || true
  mkdir -p /etc/systemd/system/; mv -f kube-controller-manager.service /etc/systemd/system/ || true
  cp -f kube-scheduler.kubeconfig /var/lib/kubernetes/ || true
  mv -f kube-scheduler.yaml /etc/kubernetes/config/ || true
  mkdir -p /etc/systemd/system/; mv -f kube-scheduler.service /etc/systemd/system/ || true
  systemctl daemon-reload
  systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  systemctl start kube-apiserver kube-controller-manager kube-scheduler
  sleep 10
  kubectl cluster-info --kubeconfig admin.kubeconfig || true
  kubectl apply -f kube-apiserver-to-kubelet.yaml --kubeconfig admin.kubeconfig || true
EOF

MACHINES_TXT="${MACHINES_TXT:-${DIR}/kubernetes-the-hard-way/machines.txt}"
SERVER_IP=$(awk '$3 == "server" {print $1}' "${MACHINES_TXT}" || echo "192.168.56.10")
curl --cacert "${LIBSCRIPT_DATA_DIR}/ca.crt" "https://${SERVER_IP}:6443/version" || true
