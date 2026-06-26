#!/bin/sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
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
