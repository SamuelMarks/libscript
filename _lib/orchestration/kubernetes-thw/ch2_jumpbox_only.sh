#!/bin/sh
# ## Overview
# Automates Chapter 2 (Client Tools) of Kubernetes the Hard Way.
#
# ## Usage
# Clones the kelseyhightower repo and downloads required client and cluster binaries to the jumpbox.


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

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md

libscript_depends wget curl vim openssl git

if [ ! -d "kubernetes-the-hard-way" ]; then
  git clone --depth 1 \
    https://github.com/kelseyhightower/kubernetes-the-hard-way.git
fi

PREVIOUS_WD="$(pwd)"

cd kubernetes-the-hard-way
ARCH="$(dpkg --print-architecture)"
mkdir -p 'downloads'
while read -r URL || [ -n "$URL" ]; do
  [ -z "$URL" ] && continue
  URL=$(printf '%s' "$URL" | tr -d '\r')
  libscript_download "$URL" "downloads/$(basename "$URL")"
done < "downloads-${ARCH}.txt"

mkdir -p 'downloads/client' 'downloads/cni-plugins' 'downloads/controller' 'downloads/worker'
tar -xvf 'downloads/crictl-v1.32.0-linux-'"${ARCH}"'.tar.gz' \
  -C 'downloads/worker/'
tar -xvf 'downloads/containerd-2.1.0-beta.0-linux-'"${ARCH}"'.tar.gz' \
  --strip-components 1 \
  -C 'downloads/worker/'
tar -xvf 'downloads/cni-plugins-linux-'"${ARCH}"'-v1.6.2.tgz' \
  -C 'downloads/cni-plugins/'
tar -xvf 'downloads/etcd-v3.6.0-rc.3-linux-'"${ARCH}"'.tar.gz' \
  -C 'downloads/' \
  --strip-components 1 \
  'etcd-v3.6.0-rc.3-linux-'"${ARCH}"'/etcdctl' \
  'etcd-v3.6.0-rc.3-linux-'"${ARCH}"'/etcd'
for f in 'downloads/kubectl' 'downloads/etcdctl'; do
  mv "${f}" 'downloads/client/'
done
for d in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'; do
  mv 'downloads/'"${D}" 'downloads/controller/'
done
for d in 'kubelet' 'kube-proxy'; do
  mv 'downloads/'"${D}" 'downloads/worker/'
done

mv 'downloads/runc.'"${ARCH}" 'downloads/worker/runc'

set +f
rm -rf 'downloads/'*'gz'
for d in 'client' 'cni-plugins' 'controller' 'worker'; do
  chmod +x 'downloads/'"${D}"'/'*
done
set -feu
priv  cp 'downloads/client/kubectl' '/usr/local/bin/'
kubectl version --client

cd -- "${PREVIOUS_WD}"
