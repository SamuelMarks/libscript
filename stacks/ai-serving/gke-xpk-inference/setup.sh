#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi


CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and GCP_ZONE must be explicitly specified."
  exit 1
fi

echo "Setting up XPK Production Cluster Stack..."

gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

echo "Creating GKE cluster $CLUSTER_NAME via xpk..."
"$(dirname "$0")/../../../_lib/cloud-providers/gcp/gke-tpu-cluster/cli.sh" create "$CLUSTER_NAME"

echo "Setup complete."
