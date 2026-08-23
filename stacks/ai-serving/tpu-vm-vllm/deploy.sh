#!/bin/sh
# ## Overview
# Manages the deployment workflow for the TPU VM vLLM AI serving stack stack.
# 
# ## Usage
# Execute this script to deploy tpu-vm-vllm to the target environment.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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


TPU_NAME="${TPU_NAME:-ml-tpu-vm}"
MODEL_NAME="${MODEL_NAME:-your-org/your-model-name}"
if [ "$MODEL_NAME" = "your-org/your-model-name" ] || [ -z "$MODEL_NAME" ]; then
  printf '%s\n' "[ERROR] MODEL_NAME must be explicitly specified (cannot be empty or the placeholder)."
  exit 1
fi

printf '%s\n' "Deploying $MODEL_NAME to TPU VM $TPU_NAME..."

# The deployment script runs commands via SSH on the TPU VM
cat << 'EOF' > /tmp/deploy_tpu.sh
set -ex

# Install docker if not present
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y docker.io
  sudo usermod -aG docker $USER
fi

MODEL_NAME="$1"

# Use JetStream image for vLLM/TPU serving (or vLLM tpu image)
IMAGE="us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"

sudo docker pull $IMAGE

# Start the container
sudo docker run -d --rm \
  --name vllm-server \
  --privileged \
  --network host \
  -v /dev:/dev \
  $IMAGE \
  --model "$MODEL_NAME" \
  --tensor-parallel-size 1
EOF

"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" "sh -s" < /tmp/deploy_tpu.sh "$MODEL_NAME"

printf '%s\n' "Deploy complete."
