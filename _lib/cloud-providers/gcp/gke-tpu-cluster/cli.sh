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

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# Ensure xpk is available
if ! command -v xpk >/dev/null 2>&1; then
  # Fallback to libscript installed
  if [ -x "${LIBSCRIPT_ROOT_DIR}/installed/xpk/bin/xpk" ]; then
    export PATH="${LIBSCRIPT_ROOT_DIR}/installed/xpk/bin:${PATH}"
  else
    log_error "xpk not found in PATH. Please install the toolchains/xpk component first."
    exit 1
  fi
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 <action> [args...]"
  echo "See README.md for details."
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
    log_info "Creating GKE cluster $CLUSTER_NAME via xpk in $GCP_ZONE..."
    xpk cluster create \
      --cluster "$CLUSTER_NAME" \
      --zone "$GCP_ZONE" \
      --tpu-type "$TPU_ACCELERATOR_TYPE" \
      $PROJECT_FLAG
    log_info "Cluster $CLUSTER_NAME created."
    ;;
  delete)
    if [ -z "$CLUSTER_NAME" ]; then log_error "Usage: gke-tpu-cluster delete <name>"; exit 1; fi
    log_info "Deleting GKE cluster $CLUSTER_NAME via xpk..."
    xpk cluster delete \
      --cluster "$CLUSTER_NAME" \
      --zone "$GCP_ZONE" \
      $PROJECT_FLAG
    log_info "Cluster $CLUSTER_NAME deleted."
    ;;
  *)
    log_error "Unknown action: $ACTION. Supported: create, delete."
    exit 1
    ;;
esac
