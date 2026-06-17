#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  exit 0
fi

"$(dirname "$0")/../../../_lib/cloud-providers/gcp/cli/setup.sh"
"$(dirname "$0")/../../../_lib/toolchains/python/setup.sh"
"$(dirname "$0")/../../../_lib/orchestration/kubernetes/kubectl/setup.sh"
"$(dirname "$0")/../../../_lib/toolchains/xpk/setup.sh"

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified for XPK clusters."
  exit 1
fi

echo "Authenticating with GCP..."
"$(dirname "$0")/../../../_lib/cloud-providers/gcp/cli/cli.sh" auth

echo "Provisioning XPK cluster: $CLUSTER_NAME..."
xpk cluster create --cluster "$CLUSTER_NAME" --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE"

echo "Setup complete."