#!/bin/sh
set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0"
  echo "See README.md for details."
  exit 0
fi


TPU_NAME="${TPU_NAME:-ml-tpu-vm}"
MODEL_NAME="${MODEL_NAME:-your-org/your-model-name}"
if [ "$MODEL_NAME" = "your-org/your-model-name" ] || [ -z "$MODEL_NAME" ]; then
  echo "[ERROR] MODEL_NAME must be explicitly specified (cannot be empty or the placeholder)."
  exit 1
fi

echo "Deploying $MODEL_NAME to TPU VM $TPU_NAME..."

# The deployment script runs commands via SSH on the TPU VM
cat << 'EOF' > /tmp/deploy_tpu.sh
#!/bin/bash
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

"$(dirname "$0")/../../../_lib/cloud-providers/gcp/tpu-vm/cli.sh" ssh "$TPU_NAME" "bash -s" < /tmp/deploy_tpu.sh "$MODEL_NAME"

echo "Deploy complete."
