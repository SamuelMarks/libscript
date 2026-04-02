#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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

for lib in '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

# github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md

depends wget curl vim openssl git

git clone --depth 1 \
  https://github.com/kelseyhightower/kubernetes-the-hard-way.git

previous_wd="$(pwd)"

cd kubernetes-the-hard-way
ARCH="$(dpkg --print-architecture)"
mkdir -p 'downloads'
while read -r url || [ -n "$url" ]; do
  [ -z "$url" ] && continue
  url=$(printf '%s' "$url" | tr -d '\r')
  libscript_download "$url" "downloads/$(basename "$url")"
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
  mv 'downloads/'"${d}" 'downloads/controller/'
done
for d in 'kubelet' 'kube-proxy'; do
  mv 'downloads/'"${d}" 'downloads/worker/'
done

mv 'downloads/runc.'"${ARCH}" 'downloads/worker/runc'

set +f
rm -rf 'downloads/'*'gz'
for d in 'client' 'cni-plugins' 'controller' 'worker'; do
  chmod +x 'downloads/'"${d}"'/'*
done
set -f
priv  cp 'downloads/client/kubectl' '/usr/local/bin/'
kubectl version --client

cd -- "${previous_wd}"
