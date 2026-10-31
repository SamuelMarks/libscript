#!/bin/sh
# ## Overview
# Idempotently submits the GKE XPK distributed training workload to the target TPU cluster.
# Supports --docker-image, --command, --tpu-type, --num-slices, --spot, and HF_TOKEN injection.
#
# ## Usage
# ./payloads/ai/gke-xpk-training/deploy.sh [--command <cmd>] [--docker-image <img>] [--tpu-type <type>] [--num-slices <n>] [--spot] [--help]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# ## print_usage
# Prints usage instructions for gke-xpk-training deploy.sh.
print_usage() {
  printf '%s
' "Usage: $0 [--command <cmd>] [--docker-image <img>] [--tpu-type <type>] [--num-slices <n>] [--spot] [--env <K=V>] [--help]"
}

EXTRA_ENV_FLAGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) print_usage; exit 0 ;;
    --command) TRAIN_SCRIPT="$2"; shift 2 ;;
    --docker-image) DOCKER_IMAGE="$2"; shift 2 ;;
    --tpu-type) TPU_ACCELERATOR_TYPE="$2"; shift 2 ;;
    --num-slices) TPU_SLICE_COUNT="$2"; shift 2 ;;
    --spot) TPU_SCHEDULING_TYPE="spot"; shift ;;
    --on-demand) TPU_SCHEDULING_TYPE="on-demand"; shift ;;
    --env) EXTRA_ENV_FLAGS="${EXTRA_ENV_FLAGS} --env $2"; shift 2 ;;
    *) shift ;;
  esac
done

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-training-job}"
TRAIN_SCRIPT="${TRAIN_SCRIPT:-${ML_SCRIPT:-${TRAIN_CMD:-python train.py}}}"
TPU_SLICE_COUNT="${TPU_SLICE_COUNT:-${NUM_SLICES:-1}}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  log_error 'GCP_PROJECT_ID and GCP_ZONE must be explicitly specified for XPK workload.'
  exit 1
fi

if [ -z "${DOCKER_IMAGE:-}" ]; then
  log_error 'DOCKER_IMAGE must be specified.'
  exit 1
fi

if xpk workload list --cluster "$CLUSTER_NAME" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" 2>/dev/null | grep -q "$WORKLOAD_NAME"; then
  log_info "Workload $WORKLOAD_NAME already exists on cluster $CLUSTER_NAME. Skipping duplicate submission."
  exit 0
fi

log_info "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."
EXTRA_XPK_FLAGS="--num-slices=${TPU_SLICE_COUNT}"
if [ "${TPU_SCHEDULING_TYPE:-}" = "spot" ]; then
  EXTRA_XPK_FLAGS="$EXTRA_XPK_FLAGS --spot"
elif [ "${TPU_SCHEDULING_TYPE:-}" = "on-demand" ]; then
  EXTRA_XPK_FLAGS="$EXTRA_XPK_FLAGS --on-demand"
fi
if [ -n "${HF_TOKEN:-}" ]; then
  EXTRA_XPK_FLAGS="$EXTRA_XPK_FLAGS --env HF_TOKEN=${HF_TOKEN}"
fi
if [ -n "$EXTRA_ENV_FLAGS" ]; then
  EXTRA_XPK_FLAGS="${EXTRA_XPK_FLAGS}${EXTRA_ENV_FLAGS}"
fi

# shellcheck disable=SC2086
xpk workload create --cluster "$CLUSTER_NAME" --workload "$WORKLOAD_NAME" --command "$TRAIN_SCRIPT" --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" --docker-image "$DOCKER_IMAGE" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" $EXTRA_XPK_FLAGS

log_info 'Deploy complete.'
