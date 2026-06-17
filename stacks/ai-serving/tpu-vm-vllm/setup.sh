#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi


# Setup Script: Authenticate GCP -> Check for/Create TPU VM in specified zone.

TPU_NAME="${TPU_NAME:-ml-tpu-vm}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

echo "Setting up TPU VM Prototyping Stack..."

# Authenticate GCP is handled by the cli component installation if not authenticated,
# but we can explicitly call it.
gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

echo "Creating TPU VM $TPU_NAME..."
"${LIBSCRIPT_ROOT_DIR}/installed/gcp-cli/bin/tpu-vm-cli" create "$TPU_NAME" || \
  "$(dirname "$0")/../../../_lib/cloud-providers/gcp/tpu-vm/cli.sh" create "$TPU_NAME"

echo "Setup complete."
