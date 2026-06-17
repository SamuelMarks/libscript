#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi

TPU_NAME="${TPU_NAME:-ml-eval-node}"
TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-200}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

echo "Setting up Comprehensive ML Training Stack on $TPU_NAME..."

gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

echo "Provisioning TPU VM with $TPU_DATA_DISK_SIZE GB persistent disk..."
"$(dirname "$0")/../../../_lib/cloud-providers/gcp/tpu-vm/cli.sh" create "$TPU_NAME"

echo "Setup complete."
