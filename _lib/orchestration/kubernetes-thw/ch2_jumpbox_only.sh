#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for LIB in '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md

depends wget curl vim openssl git

git clone --depth 1 \
  https://github.com/kelseyhightower/kubernetes-the-hard-way.git

PREVIOUS_WD="$(pwd)"

cd kubernetes-the-hard-way
ARCH="$(dpkg --print-architecture)"
mkdir -p 'downloads'
while read -r url || [ -n "$URL" ]; do
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
set -f
priv  cp 'downloads/client/kubectl' '/usr/local/bin/'
kubectl version --client

cd -- "${PREVIOUS_WD}"
