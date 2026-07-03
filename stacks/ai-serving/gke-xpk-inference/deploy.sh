#!/bin/sh
# ## Overview
# Manages the deployment workflow for the GKE XPK inference stack stack.
# 
# ## Usage
# Execute this script to deploy gke-xpk-inference to the target environment.


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
MODEL_NAME="${MODEL_NAME:-your-org/your-model-name}"
if [ "$MODEL_NAME" = "your-org/your-model-name" ] || [ -z "$MODEL_NAME" ]; then
  printf '%s\n' "[ERROR] MODEL_NAME must be explicitly specified (cannot be empty or the placeholder)."
  exit 1
fi
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-serve}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified."
  exit 1
fi

printf '%s\n' "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."

# Generate an xpk workload create command
xpk workload create \
  --cluster "$CLUSTER_NAME" \
  --workload "$WORKLOAD_NAME" \
  --command "python -m vllm.entrypoints.openai.api_server --model $MODEL_NAME --tensor-parallel-size \${TPU_TENSOR_PARALLEL_SIZE:-1}" \
  --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" \
  --project "$GCP_PROJECT_ID" \
  --zone "$GCP_ZONE" \
  --docker-image "us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"

printf '%s\n' "Deploy complete."
