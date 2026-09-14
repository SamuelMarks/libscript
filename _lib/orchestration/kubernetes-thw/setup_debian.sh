#!/bin/sh
# ## Overview
# Debian setup script for Kubernetes the Hard Way.
#
# ## Usage
# Executes the `ch*` scripts in sequence to bootstrap the cluster.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${HOME}/.libscript_k8s_data}"
export LIBSCRIPT_DATA_DIR
mkdir -p "${LIBSCRIPT_DATA_DIR}"

for LIB in "_lib/_common/environ.sh" "_lib/_common/pkg_mgr.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

# Ensure 'server' hostname and localhost ssh loopback are available for single-node execution
if ! getent hosts server >/dev/null 2>&1; then
  if [ -w /etc/hosts ]; then
    printf '127.0.0.1 server node-0 node-1\n' >> /etc/hosts
  elif command -v sudo >/dev/null 2>&1; then
    printf '127.0.0.1 server node-0 node-1\n' | sudo tee -a /etc/hosts >/dev/null || true
  fi
fi

if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@server echo ok >/dev/null 2>&1; then
  mkdir -p ~/.ssh /root/.ssh 2>/dev/null || true
  if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa 2>/dev/null || true
  fi
  if [ -f ~/.ssh/id_rsa.pub ]; then
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 2>/dev/null || true
    if [ -w /root/.ssh ]; then
      cat ~/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys 2>/dev/null || true
    elif command -v sudo >/dev/null 2>&1; then
      sudo mkdir -p /root/.ssh 2>/dev/null || true
      cat ~/.ssh/id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys >/dev/null || true
    fi
  fi
  ssh-keyscan 127.0.0.1 server >> ~/.ssh/known_hosts 2>/dev/null || true
fi

# Ensure SSH does not prompt interactively for host authenticity verification
if [ ! -f ~/.ssh/config ] || ! grep -q "StrictHostKeyChecking no" ~/.ssh/config 2>/dev/null; then
  mkdir -p ~/.ssh
  printf 'Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n' >> ~/.ssh/config
  chmod 600 ~/.ssh/config 2>/dev/null || true
fi

for LIB in 'ch2_jumpbox_only.sh' 'ch4_jumpbox_to_targets.sh' 'ch5_jumpbox_to_targets.sh' 'ch6_jumpbox_to_server.sh' 'ch7_jumpbox_to_server.sh'; do
  SCRIPT_NAME="${DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

if [ -n "${KUBERNETES_THW_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${KUBERNETES_THW_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${KUBERNETES_THW_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${KUBERNETES_THW_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${KUBERNETES_THW_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${KUBERNETES_THW_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${KUBERNETES_THW_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${KUBERNETES_THW_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
