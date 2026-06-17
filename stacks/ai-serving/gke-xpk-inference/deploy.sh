#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi


CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
MODEL_NAME="${MODEL_NAME:-your-org/your-model-name}"
if [ "$MODEL_NAME" = "your-org/your-model-name" ] || [ -z "$MODEL_NAME" ]; then
  echo "[ERROR] MODEL_NAME must be explicitly specified (cannot be empty or the placeholder)."
  exit 1
fi
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-serve}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified."
  exit 1
fi

echo "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."

# Generate an xpk workload create command
xpk workload create \
  --cluster "$CLUSTER_NAME" \
  --workload "$WORKLOAD_NAME" \
  --command "python -m vllm.entrypoints.openai.api_server --model $MODEL_NAME --tensor-parallel-size \${TPU_TENSOR_PARALLEL_SIZE:-1}" \
  --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" \
  --project "$GCP_PROJECT_ID" \
  --zone "$GCP_ZONE" \
  --docker-image "us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"

echo "Deploy complete."
