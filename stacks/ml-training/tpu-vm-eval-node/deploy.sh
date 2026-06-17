#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi

TPU_NAME="${TPU_NAME:-ml-eval-node}"
BUCKET_NAME="${BUCKET_NAME:-}"
ML_SCRIPT="${ML_SCRIPT:-python train.py}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  echo "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

if [ -z "$BUCKET_NAME" ]; then
  echo "[ERROR] BUCKET_NAME must be set for GCS FUSE."
  exit 1
fi

PROJECT_FLAG="--project=$GCP_PROJECT_ID"

echo "Deploying execution loop to $TPU_NAME..."

echo "Syncing libscript components to TPU VM..."
gcloud compute tpus tpu-vm scp --recurse "$(dirname "$0")/../../../_lib" "$TPU_NAME:~/" --zone="$TPU_ZONE" $PROJECT_FLAG

echo "Installing components on TPU VM..."
gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG --command "
  ~/_lib/storage-layers/gcsfuse/setup.sh &&
  ~/_lib/utilities/tmux/setup.sh &&
  ~/_lib/logging/tensorboard/setup.sh
"

cat << 'EOF' > /tmp/ml_deploy.sh
#!/bin/bash
set -ex

# Mount bucket
BUCKET_NAME="$1"
mkdir -p /mnt/ml_data
gcsfuse --implicit-dirs "$BUCKET_NAME" /mnt/ml_data

# Start Tensorboard in background
~/_lib/logging/tensorboard/cli.sh start /mnt/ml_data/logs 6006 || tensorboard --logdir=/mnt/ml_data/logs --port=6006 --host=0.0.0.0 &

# The training script will be executed via the detached SSH wrapper
EOF

"$(dirname "$0")/../../../_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" "bash -s" < /tmp/ml_deploy.sh "$BUCKET_NAME"

echo "Triggering detached training session and port-forwarding TensorBoard..."
"$(dirname "$0")/../../../_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" --detached --forward-port 6006:localhost:6006 "cd /mnt/ml_data && $ML_SCRIPT"

echo "Deploy complete. TensorBoard is available at http://localhost:6006"
echo "To re-attach to the training session, run: tpu-vm ssh $TPU_NAME 'tmux attach'"
