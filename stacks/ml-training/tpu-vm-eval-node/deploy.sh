#!/bin/sh
# ## Overview
# Manages the deployment workflow for the TPU VM evaluation node for ML stack.
# 
# ## Usage
# Execute this script to deploy tpu-vm-eval-node to the target environment.


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

TPU_NAME="${TPU_NAME:-ml-eval-node}"
BUCKET_NAME="${BUCKET_NAME:-}"
ML_SCRIPT="${ML_SCRIPT:-python train.py}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

if [ -z "$BUCKET_NAME" ]; then
  printf '%s\n' "[ERROR] BUCKET_NAME must be set for GCS FUSE."
  exit 1
fi

PROJECT_FLAG="--project=$GCP_PROJECT_ID"

printf '%s\n' "Deploying execution loop to $TPU_NAME..."

printf '%s\n' "Syncing libscript components to TPU VM..."
gcloud compute tpus tpu-vm scp --recurse "${LIBSCRIPT_ROOT_DIR}/_lib" "$TPU_NAME:~/" --zone="$TPU_ZONE" $PROJECT_FLAG

printf '%s\n' "Installing components on TPU VM..."
gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG --command "
  ~/_lib/storage-layers/gcsfuse/setup.sh &&
  ~/_lib/utilities/tmux/setup.sh &&
  ~/_lib/logging/tensorboard/setup.sh
"

cat << 'EOF' > /tmp/ml_deploy.sh
set -ex

# Mount bucket
BUCKET_NAME="$1"
mkdir -p /mnt/ml_data
gcsfuse --implicit-dirs "$BUCKET_NAME" /mnt/ml_data

# Start Tensorboard in background
~/_lib/logging/tensorboard/cli.sh start /mnt/ml_data/logs 6006 || tensorboard --logdir=/mnt/ml_data/logs --port=6006 --host=0.0.0.0 &

# The training script will be executed via the detached SSH wrapper
EOF

"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" "sh -s" < /tmp/ml_deploy.sh "$BUCKET_NAME"

printf '%s\n' "Triggering detached training session and port-forwarding TensorBoard..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" --detached --forward-port 6006:localhost:6006 "cd /mnt/ml_data && $ML_SCRIPT"

printf '%s\n' "Deploy complete. TensorBoard is available at http://localhost:6006"
printf '%s\n' "To re-attach to the training session, run: tpu-vm ssh $TPU_NAME 'tmux attach'"
