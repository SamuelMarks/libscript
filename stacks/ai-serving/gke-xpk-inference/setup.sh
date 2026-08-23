#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the GKE XPK inference stack stack.
# 
# ## Usage
# Execute this script to install and configure gke-xpk-inference on the local system.


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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

# Walk up to find root
_root="$SCRIPT_DIR"
while [ ! -f "$_root/ROOT" ] && [ "$_root" != "/" ]; do
    _root=$(dirname "$_root")
done
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$_root}"

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
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified."
  exit 1
fi

printf '%s\n' "Setting up XPK Production Cluster Stack..."

gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

printf '%s\n' "Creating GKE cluster $CLUSTER_NAME via xpk..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/gke-tpu-cluster/cli.sh" create "$CLUSTER_NAME"

printf '%s\n' "Setup complete."
