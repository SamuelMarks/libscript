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


libscript_depends wget curl vim openssl git


if [ ! -d "${DIR}/kubernetes-the-hard-way/.git" ]; then mv "${DIR}/kubernetes-the-hard-way/machines.txt" . 2>/dev/null || true; rm -rf "${DIR}/kubernetes-the-hard-way"; git clone --depth 1 https://github.com/kelseyhightower/kubernetes-the-hard-way.git "${DIR}/kubernetes-the-hard-way"; mv machines.txt "${DIR}/kubernetes-the-hard-way/" 2>/dev/null || true; fi

PREVIOUS_WD="$(pwd)"
cd "${DIR}/kubernetes-the-hard-way"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi
mkdir -p 'downloads'

while read -r URL || [ -n "$URL" ]; do
  [ -z "$URL" ] && continue
  URL=$(printf '%s' "$URL" | tr -d '\r')
  FILE="downloads/$(basename "$URL")"
  if [ ! -f "$FILE" ]; then
    curl -sL -o "$FILE" "$URL"
  fi
done < "downloads-${ARCH}.txt"

mkdir -p 'downloads/client' 'downloads/cni-plugins' 'downloads/controller' 'downloads/worker'

if [ -f "downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz" ]; then
  tar -xzf "downloads/crictl-v1.32.0-linux-${ARCH}.tar.gz" -C 'downloads/worker/'
fi
if [ -f "downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz" ]; then
  tar -xzf "downloads/containerd-2.1.0-beta.0-linux-${ARCH}.tar.gz" --strip-components 1 -C 'downloads/worker/'
fi
if [ -f "downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz" ]; then
  tar -xzf "downloads/cni-plugins-linux-${ARCH}-v1.6.2.tgz" -C 'downloads/cni-plugins/'
fi
if [ -f "downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz" ]; then
  tar -xzf "downloads/etcd-v3.6.0-rc.3-linux-${ARCH}.tar.gz" -C 'downloads/' --strip-components 1
fi

for f in 'downloads/kubectl' 'downloads/etcdctl'; do
  [ -f "${f}" ] && mv -f "${f}" 'downloads/client/'
done
for d in 'etcd' 'kube-apiserver' 'kube-controller-manager' 'kube-scheduler'; do
  [ -f "downloads/${d}" ] && mv -f "downloads/${d}" 'downloads/controller/'
done
for d in 'kubelet' 'kube-proxy'; do
  [ -f "downloads/${d}" ] && mv -f "downloads/${d}" 'downloads/worker/'
done

[ -f "downloads/runc.${ARCH}" ] && mv -f "downloads/runc.${ARCH}" 'downloads/worker/runc'

set +f
for d in 'client' 'cni-plugins' 'controller' 'worker'; do
  if [ -d "downloads/${d}" ]; then
    chmod +x "downloads/${d}/"* 2>/dev/null || true
  fi
done
set -feu

cp -f 'downloads/client/kubectl' '.' || true
chmod +x ./kubectl || true
chmod +x ./kubectl || true
./kubectl version --client >/dev/null 2>&1 || true
cd -- "${PREVIOUS_WD}"
