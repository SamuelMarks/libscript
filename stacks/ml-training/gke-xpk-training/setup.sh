#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the GKE XPK machine learning training stack stack.
# 
# ## Usage
# Execute this script to install and configure gke-xpk-training on the local system.


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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0"
  exit 0
fi

"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/cli/setup.sh"
"${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/python/setup.sh"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/kubernetes/kubectl/setup.sh"
"${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/xpk/setup.sh"

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified for XPK clusters."
  exit 1
fi

printf '%s\n' "Authenticating with GCP..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/cli/cli.sh" auth

printf '%s\n' "Provisioning XPK cluster: $CLUSTER_NAME..."
xpk cluster create --cluster "$CLUSTER_NAME" --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE"

printf '%s\n' "Setup complete."
