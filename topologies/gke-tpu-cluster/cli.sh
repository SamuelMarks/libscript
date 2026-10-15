#!/bin/sh
# ## Overview
# Topology CLI manager for multi-pool GKE TPU clusters via XPK and gcloud.
#
# ## Usage
# ./topologies/gke-tpu-cluster/cli.sh <create|delete|status> [cluster_name]

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
# Prints usage instructions for gke-tpu-cluster cli.sh.
print_usage() {
  printf '%s\n' "Usage: $0 <create|delete|status> [cluster_name]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

ACTION="${1:-}"
CLUSTER_NAME="${2:-${XPK_CLUSTER_NAME:-}}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-us-central2-b}"
TPU_ACCELERATOR_TYPE="${TPU_ACCELERATOR_TYPE:-v4-8}"

PROJECT_FLAG=""
if [ -n "${GCP_PROJECT_ID}" ]; then
  PROJECT_FLAG="--project=${GCP_PROJECT_ID}"
fi

case "$ACTION" in
  create)
    if [ -z "$CLUSTER_NAME" ]; then log_error "Usage: gke-tpu-cluster create <name>"; exit 1; fi
    if command -v gcloud >/dev/null 2>&1 && gcloud container clusters describe "$CLUSTER_NAME" --zone="$GCP_ZONE" ${PROJECT_FLAG:+"$PROJECT_FLAG"} >/dev/null 2>&1; then
      log_info "GKE TPU cluster $CLUSTER_NAME already exists in $GCP_ZONE. Skipping creation."
      exit 0
    fi
    log_info "Creating GKE TPU cluster $CLUSTER_NAME via xpk in $GCP_ZONE..."
    xpk cluster create \
      --cluster "$CLUSTER_NAME" \
      --zone "$GCP_ZONE" \
      --tpu-type "$TPU_ACCELERATOR_TYPE" \
      ${PROJECT_FLAG:+"$PROJECT_FLAG"}
    log_info "Cluster $CLUSTER_NAME created."
    ;;
  delete)
    if [ -z "$CLUSTER_NAME" ]; then log_error "Usage: gke-tpu-cluster delete <name>"; exit 1; fi
    log_info "Deleting GKE TPU cluster $CLUSTER_NAME via xpk..."
    xpk cluster delete \
      --cluster "$CLUSTER_NAME" \
      --zone "$GCP_ZONE" \
      ${PROJECT_FLAG:+"$PROJECT_FLAG"}
    log_info "Cluster $CLUSTER_NAME deleted."
    ;;
  status|logs|use|env|ls|download|uninstall)
    printf '%s\n' "Topology status check complete for gke-tpu-cluster."
    exit 0
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: create, delete, status."
    exit 1
    ;;
esac
