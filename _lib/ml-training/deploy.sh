#!/bin/sh
# ## Overview
# Manages the deployment workflow for the TPU VM evaluation node for ML stack.
# Supports APP_DIR/REPO_DIR syncing, libscript.json/pyproject.toml dependency installation,
# optional BUCKET_NAME FUSE mounting, and safe environment secret forwarding.
# 
# ## Usage
# Execute this script to deploy tpu-vm-eval-node to the target environment.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s
' "Usage: $0"
  printf '%s
' "See README.md for details."
  exit 0
fi

TPU_NAME="${TPU_NAME:-ml-eval-node}"
BUCKET_NAME="${BUCKET_NAME:-${GCS_BUCKET:-}}"
BUCKET_NAME="${BUCKET_NAME#gs://}"
ML_SCRIPT="${ML_SCRIPT:-${TRAIN_CMD:-${TRAIN_SCRIPT:-python train.py}}}"
TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-${DISK_SIZE_GB:-200}}"
DISK_NAME="${DISK_NAME:-${TPU_NAME}-data}"
APP_DIR="${APP_DIR:-${REPO_DIR:-}}"
if [ -z "$APP_DIR" ]; then
  if [ -f "./libscript.json" ] || [ -f "./pyproject.toml" ] || [ -f "./requirements.txt" ]; then
    APP_DIR="$(pwd)"
  fi
fi
export TPU_NAME BUCKET_NAME ML_SCRIPT TPU_DATA_DISK_SIZE DISK_NAME APP_DIR

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  printf '%s
' "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

PROJECT_FLAG="--project=$GCP_PROJECT_ID"

printf '%s
' "Deploying execution loop to $TPU_NAME..."

printf '%s
' "Syncing libscript components to TPU VM..."
gcloud compute tpus tpu-vm scp --recurse "${LIBSCRIPT_ROOT_DIR}/_lib" "$TPU_NAME:~/" --zone="$TPU_ZONE" "$PROJECT_FLAG"

if [ -n "$APP_DIR" ] && [ -d "$APP_DIR" ]; then
  printf 'Syncing application repository (%s) to ~/workspace on TPU VM...
' "$APP_DIR"
  gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" "$PROJECT_FLAG" --command "mkdir -p ~/workspace"
  gcloud compute tpus tpu-vm scp --recurse "$APP_DIR/." "$TPU_NAME:~/workspace/" --zone="$TPU_ZONE" "$PROJECT_FLAG"
fi

# Generate temporary secrets env file to copy to remote VM without leaking into ps
TMP_ENV_FILE=$(mktemp "${TMPDIR:-/tmp}/libscript_ml_env.XXXXXX")
trap 'rm -f "$TMP_ENV_FILE" /tmp/ml_deploy.sh' EXIT
chmod 600 "$TMP_ENV_FILE"
for _sec_key in HF_TOKEN WANDB_API_KEY KERAS_BACKEND JAX_PLATFORMS MODEL_NAME DATASET_NAME DUCKDB_PATH DUCKDB_TABLE DUCKDB_URL; do
  _sec_val=$(printenv "$_sec_key" 2>/dev/null || true)
  if [ -n "$_sec_val" ]; then
    printf 'export %s=%s
' "$_sec_key" "'$(printf '%s' "$_sec_val" | sed "s/'/'''/g")'" >> "$TMP_ENV_FILE"
  fi
done
gcloud compute tpus tpu-vm scp "$TMP_ENV_FILE" "$TPU_NAME:~/.env.ml_secrets" --zone="$TPU_ZONE" "$PROJECT_FLAG"

printf '%s
' "Installing components on TPU VM..."
gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" "$PROJECT_FLAG" --command "
  ~/_lib/storage-layers/gcsfuse/setup.sh &&
  ~/_lib/utilities/tmux/setup.sh &&
  ~/_lib/logging/tensorboard/setup.sh
"

cat << 'EOF' > /tmp/ml_deploy.sh
set -ex

BUCKET_NAME="${1:-}"
if [ -n "$BUCKET_NAME" ]; then
  mkdir -p /mnt/ml_data
  gcsfuse --implicit-dirs "$BUCKET_NAME" /mnt/ml_data || true
  WORK_DATA_DIR="/mnt/ml_data"
else
  mkdir -p "$HOME/workspace/data"
  WORK_DATA_DIR="$HOME/workspace/data"
fi

if [ -f "$HOME/workspace/libscript.json" ] && [ -f "$HOME/libscript/libscript.sh" ]; then
  "$HOME/libscript/libscript.sh" install-deps "$HOME/workspace/libscript.json" || true
fi
if [ -f "$HOME/workspace/pyproject.toml" ] || [ -f "$HOME/workspace/requirements.txt" ]; then
  (
    cd "$HOME/workspace"
    if command -v uv >/dev/null 2>&1; then
      if [ -f "pyproject.toml" ]; then uv pip install --system -e . || true; fi
      if [ -f "requirements.txt" ]; then uv pip install --system -r requirements.txt || true; fi
    elif command -v pip >/dev/null 2>&1; then
      if [ -f "pyproject.toml" ]; then pip install -e . || true; fi
      if [ -f "requirements.txt" ]; then pip install -r requirements.txt || true; fi
    fi
  )
fi

mkdir -p "${WORK_DATA_DIR}/logs"
~/_lib/logging/tensorboard/cli.sh start "${WORK_DATA_DIR}/logs" 6006 || tensorboard --logdir="${WORK_DATA_DIR}/logs" --port=6006 --host=0.0.0.0 &
EOF

"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh" ssh "$TPU_NAME" "sh -s" < /tmp/ml_deploy.sh "$BUCKET_NAME"

REMOTE_RUN_DIR='/mnt/ml_data'
if [ -z "$BUCKET_NAME" ]; then
  REMOTE_RUN_DIR="\$HOME/workspace"
elif [ -n "$APP_DIR" ]; then
  REMOTE_RUN_DIR="\$HOME/workspace"
fi

printf '%s\n' 'Triggering detached training session and port-forwarding TensorBoard...'
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh" ssh "$TPU_NAME" --detached --forward-port 6006:localhost:6006 "if [ -f ~/.env.ml_secrets ]; then . ~/.env.ml_secrets; fi && cd $REMOTE_RUN_DIR && $ML_SCRIPT"

printf '%s
' "Deploy complete. TensorBoard is available at http://localhost:6006"
printf '%s
' "To re-attach to the training session, run: tpu-vm ssh $TPU_NAME 'tmux attach'"
