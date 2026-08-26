#!/bin/sh
# ## Overview
# Automates Chapter 9 (Bootstrapping Kubernetes Workers) of Kubernetes the Hard Way.
#
# ## Usage
# Installs and configures containerd, kubelet, and kube-proxy on worker nodes.

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
for HOST in $NODES; do
  SUBNET=$(grep "${HOST}" "${MACHINES_TXT}" | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" "${DIR}/kubernetes-the-hard-way/"configs/10-bridge.conf > "${DIR}/kubernetes-the-hard-way/10-bridge-${HOST}.conf"
  sed "s|SUBNET|$SUBNET|g" "${DIR}/kubernetes-the-hard-way/"configs/kubelet-config.yaml > "${DIR}/kubernetes-the-hard-way/kubelet-config-${HOST}.yaml"
  scp "${DIR}/kubernetes-the-hard-way/10-bridge-${HOST}.conf" "${DIR}/kubernetes-the-hard-way/kubelet-config-${HOST}.yaml" root@${HOST}:~/
  # shellcheck disable=SC2029

  ssh root@${HOST} "mv -f 10-bridge-${HOST}.conf 10-bridge.conf && mv -f kubelet-config-${HOST}.yaml kubelet-config.yaml"
done

for HOST in $NODES; do
  ssh root@${HOST} 'mkdir -p ~/cni-plugins'
  set +f
  scp "${DIR}/kubernetes-the-hard-way/"downloads/worker/* "${DIR}/kubernetes-the-hard-way/"downloads/client/kubectl "${DIR}/kubernetes-the-hard-way/"configs/99-loopback.conf "${DIR}/kubernetes-the-hard-way/"configs/containerd-config.toml "${DIR}/kubernetes-the-hard-way/"configs/kube-proxy-config.yaml "${DIR}/kubernetes-the-hard-way/"units/containerd.service "${DIR}/kubernetes-the-hard-way/"units/kubelet.service "${DIR}/kubernetes-the-hard-way/"units/kube-proxy.service root@${HOST}:~/
  scp "${DIR}/kubernetes-the-hard-way/"downloads/cni-plugins/* root@${HOST}:~/cni-plugins/
  set -f
done

for HOST in $NODES; do
ssh root@${HOST} << 'EOF'
  set -eu
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get -y install socat conntrack ipset kmod
  elif command -v apk >/dev/null 2>&1; then
    apk update
    apk add socat conntrack-tools ipset iptables nftables kmod gcompat
  fi
  if swapon --show 2>/dev/null | grep -q 'NAME' || free | grep -qi swap; then
    swapoff -a
  fi
  if command -v rc-update >/dev/null 2>&1; then
    rc-update add cgroups boot || true
    rc-service cgroups start || true
    if ! mount | grep -q cgroup; then
        mkdir -p /sys/fs/cgroup
        mount -t cgroup2 none /sys/fs/cgroup || mount -t tmpfs cgroup_root /sys/fs/cgroup
    fi
  fi
  mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes
  mv -f crictl kube-proxy kubelet runc /usr/local/bin/ || true
  mv -f containerd containerd-shim-runc-v2 containerd-stress /bin/ || true
  cp -rf cni-plugins/* /opt/cni/bin/ || true
  mv -f 10-bridge.conf 99-loopback.conf /etc/cni/net.d/ || true
  modprobe br-netfilter || true
  modprobe x_tables || true
  modprobe nf_nat || true
  modprobe nf_conntrack || true

  mkdir -p /etc/modules-load.d/
  if ! grep -q "br-netfilter" /etc/modules-load.d/modules.conf 2>/dev/null; then
    echo "br-netfilter" >> /etc/modules-load.d/modules.conf
  fi
  echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.d/kubernetes.conf
  echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
  sysctl -p /etc/sysctl.d/kubernetes.conf || true
  mkdir -p /etc/containerd/
  mv -f containerd-config.toml /etc/containerd/config.toml || true
  mkdir -p /etc/systemd/system/
  mv -f containerd.service /etc/systemd/system/ || true
  mv -f kubelet-config.yaml /var/lib/kubelet/ || true
  mv -f kubelet.service /etc/systemd/system/ || true
  mv -f kube-proxy-config.yaml /var/lib/kube-proxy/ || true
  mv -f kube-proxy.service /etc/systemd/system/ || true
  systemctl daemon-reload
  systemctl enable containerd kubelet kube-proxy
  systemctl start containerd kubelet kube-proxy
EOF
done

ssh root@server "kubectl get nodes --kubeconfig admin.kubeconfig" || true
