#!/bin/sh
# ## Overview
# Idempotently deploys a parameterized TPU inference workload onto a GKE XPK cluster.
# Supports custom WORKLOAD_CMD/SERVE_CMD, DOCKER_IMAGE, NUM_SLICES, TPU_SCHEDULING_TYPE, and HF_TOKEN.
#
# ## Usage
# ./payloads/ai/gke-xpk-inference/deploy.sh [--command <cmd>] [--docker-image <img >] [--num-slices <n>] [--spot] [--env <K=V>] [--help]

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
export LIBSCRIPT_ROOT_DIR

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# ## print_usage
# Prints usage instructions for gke-xpk-inference deploy.sh.
print_usage() {
  printf '%s
' "Usage: $0 [--command <cmd>] [--docker-image <img>] [--num-slices <n>] [--spot|--on-demand] [--env <K=V>] [--help]"
}

EXTRA_ENV_FLAGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) print_usage; exit 0 ;;
    --command) WORKLOAD_CMD="$2"; shift 2 ;;
    --docker-image) DOCKER_IMAGE="$2"; shift 2 ;;
    --num-slices) NUM_SLICES="$2"; shift 2 ;;
    --spot) TPU_SCHEDULING_TYPE="spot"; shift ;;
    --on-demand) TPU_SCHEDULING_TYPE="on-demand"; shift ;;
    --env) EXTRA_ENV_FLAGS="${EXTRA_ENV_FLAGS} --env $2"; shift 2 ;;
    *) shift ;;
  esac
done

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
MODEL_NAME="${MODEL_NAME:-your-org/your-model-name}"
WORKLOAD_CMD="${WORKLOAD_CMD:-${SERVE_CMD:-}}"
if [ -z "$WORKLOAD_CMD" ]; then
  if [ "$MODEL_NAME" = "your-org/your-model-name" ] || [ -z "$MODEL_NAME" ]; then
    log_error 'MODEL_NAME or WORKLOAD_CMD must be explicitly specified.'
    exit 1
  fi
  WORKLOAD_CMD="python -m vllm.entrypoints.openai.api_server --model $MODEL_NAME --tensor-parallel-size ${TPU_TENSOR_PARALLEL_SIZE:-1}"
fi

DOCKER_IMAGE="${DOCKER_IMAGE:-us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest}"
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-serve}"
NUM_SLICES="${NUM_SLICES:-${TPU_SLICE_COUNT:-1}}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  log_error 'GCP_PROJECT_ID and GCP_ZONE must be explicitly specified.'
  exit 1
fi

if xpk workload list --cluster "$CLUSTER_NAME" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" 2>/dev/null | grep -q "$WORKLOAD_NAME"; then
  log_info "Workload $WORKLOAD_NAME already exists on cluster $CLUSTER_NAME. Skipping duplicate submission."
  exit 0
fi

EXTRA_XPK_FLAGS="--num-slices=${NUM_SLICES}"
if [ "${TPU_SCHEDULING_TYPE:-}" = "spot" ]; then
  EXTRA_XPK_FLAGS="${EXTRA_XPK_FLAGS} --spot"
elif [ "${TPU_SCHEDULING_TYPE:-}" = "on-demand" ]; then
  EXTRA_XPK_FLAGS="${EXTRA_XPK_FLAGS} --on-demand"
fi
if [ -n "${HF_TOKEN:-}" ]; then
  EXTRA_XPK_FLAGS="${EXTRA_XPK_FLAGS} --env HF_TOKEN=${HF_TOKEN}"
fi
if [ -n "$EXTRA_ENV_FLAGS" ]; then
  EXTRA_XPK_FLAGS="${EXTRA_XPK_FLAGS}${EXTRA_ENV_FLAGS}"
fi

log_info "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."
# shellcheck disable=SC2086
xpk workload create --cluster "$CLUSTER_NAME" --workload "$WORKLOAD_NAME" --command "$WORKLOAD_CMD" --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" --docker-image "$DOCKER_IMAGE" $EXTRA_XPK_FLAGS

log_info 'Deploy complete.'
