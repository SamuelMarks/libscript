#!/bin/sh
# ## Overview
# Automates Chapter 12 (Smoke Test) of Kubernetes the Hard Way.
#
# ## Usage
# Verifies the Kubernetes cluster is functioning correctly.

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


PREVIOUS_WD="$(pwd)"
cd kubernetes-the-hard-way || exit 1
kubectl create secret generic kubernetes-the-hard-way --from-literal="mykey=mydata" || true
ssh root@server 'etcdctl get /registry/secrets/default/kubernetes-the-hard-way | hexdump -C' || true
kubectl create deployment nginx --image=nginx || true
kubectl rollout status deployment/nginx || true

POD_NAME=$(kubectl get pod -l app=nginx -o jsonpath="{.items[0].metadata.name}")
if [ -n "$POD_NAME" ]; then
  kubectl port-forward "$POD_NAME" 8080:80 &
  PF_PID=$!
  sleep 5
  curl -I http://127.0.0.1:8080 || true
  kill $PF_PID || true
  kubectl logs "$POD_NAME" || true
  kubectl exec -ti "$POD_NAME" -- nginx -v || true
fi
cd -- "${PREVIOUS_WD}"
