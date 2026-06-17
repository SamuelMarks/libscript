#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  exit 0
fi

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-training-job}"
TRAIN_SCRIPT="${TRAIN_SCRIPT:-python train.py}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified for XPK workload."
  exit 1
fi

if [ -z "${DOCKER_IMAGE:-}" ]; then
  echo "[ERROR] DOCKER_IMAGE must be specified."
  exit 1
fi

echo "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."

xpk workload create \
  --cluster "$CLUSTER_NAME" \
  --workload "$WORKLOAD_NAME" \
  --command "$TRAIN_SCRIPT" \
  --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" \
  --docker-image "$DOCKER_IMAGE" \
  --project "$GCP_PROJECT_ID" \
  --zone "$GCP_ZONE"

echo "Deploy complete."