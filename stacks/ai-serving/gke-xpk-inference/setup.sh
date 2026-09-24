#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the GKE XPK inference stack stack.
# 
# ## Usage
# Execute this script to install and configure gke-xpk-inference on the local system.


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
  printf '%s\n' "See README.md for details."
  exit 0
fi


CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  printf '%s\n' "[INFO] GCP_PROJECT_ID and GCP_ZONE not specified. Staging complete."
  exit 0
fi

printf '%s\n' "Setting up XPK Production Cluster Stack..."

gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

printf '%s\n' "Creating GKE cluster $CLUSTER_NAME via xpk..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/gke-tpu-cluster/cli.sh" create "$CLUSTER_NAME"

printf '%s\n' "Setup complete."
