#!/bin/sh
# ## Overview
# Idempotently submits the GKE XPK distributed training workload to the target TPU cluster.
#
# ## Usage
# ./payloads/ai/gke-xpk-training/deploy.sh [--help]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
  printf '%s\n' "Usage: $0 [--help]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
WORKLOAD_NAME="${WORKLOAD_NAME:-ml-training-job}"
TRAIN_SCRIPT="${TRAIN_SCRIPT:-python train.py}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  log_error "GCP_PROJECT_ID and GCP_ZONE must be explicitly specified for XPK workload."
  exit 1
fi

if [ -z "${DOCKER_IMAGE:-}" ]; then
  log_error "DOCKER_IMAGE must be specified."
  exit 1
fi

if xpk workload list --cluster "$CLUSTER_NAME" --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" 2>/dev/null | grep -q "$WORKLOAD_NAME"; then
  log_info "Workload $WORKLOAD_NAME already exists on cluster $CLUSTER_NAME. Skipping duplicate submission."
  exit 0
fi

log_info "Deploying workload $WORKLOAD_NAME to XPK cluster $CLUSTER_NAME..."
xpk workload create \
  --cluster "$CLUSTER_NAME" \
  --workload "$WORKLOAD_NAME" \
  --command "$TRAIN_SCRIPT" \
  --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" \
  --docker-image "$DOCKER_IMAGE" \
  --project "$GCP_PROJECT_ID" \
  --zone "$GCP_ZONE"

log_info "Deploy complete."
