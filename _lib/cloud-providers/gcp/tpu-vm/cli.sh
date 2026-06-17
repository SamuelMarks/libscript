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

SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../../../.." && pwd)}"

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# Ensure gcloud is available
if ! command -v gcloud >/dev/null 2>&1; then
  log_error "gcloud not found in PATH. Please install the gcp/cli component first."
  exit 1
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 <action> [args...]"
  echo "See README.md for details."
  exit 0
fi

ACTION="${1:-}"
TPU_NAME="${2:-${TPU_NAME:-}}"

TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$TPU_ZONE" ]; then
  log_error "TPU_ZONE must be explicitly specified (e.g., us-central2-b)."
  exit 1
fi

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
if [ -z "$GCP_PROJECT_ID" ]; then
  log_error "GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning."
  exit 1
fi

TPU_ACCELERATOR_TYPE="${TPU_ACCELERATOR_TYPE:-v4-8}"
TPU_VERSION="${TPU_VERSION:-tpu-ubuntu2204-base}"

TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-}"
TPU_DATA_DISK_TYPE="${TPU_DATA_DISK_TYPE:-pd-balanced}"

PROJECT_FLAG="--project=${GCP_PROJECT_ID}"

case "$ACTION" in
  create)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm create <name>"; exit 1; fi
    
    DISK_FLAG=""
    if [ -n "$TPU_DATA_DISK_SIZE" ]; then
      DISK_FLAG="--data-disk=source=projects/${GCP_PROJECT_ID}/zones/${TPU_ZONE}/disks/${TPU_NAME}-data,mode=read-write"
      # Check and create disk if it doesn't exist
      if ! gcloud compute disks describe "${TPU_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
        log_info "Creating persistent data disk ${TPU_NAME}-data (${TPU_DATA_DISK_SIZE}GB, ${TPU_DATA_DISK_TYPE})..."
        gcloud compute disks create "${TPU_NAME}-data" \
          --size="${TPU_DATA_DISK_SIZE}GB" \
          --type="${TPU_DATA_DISK_TYPE}" \
          --zone="$TPU_ZONE" \
          $PROJECT_FLAG
      else
        log_info "Data disk ${TPU_NAME}-data already exists."
      fi
    fi

    log_info "Checking if TPU VM $TPU_NAME exists in zone $TPU_ZONE..."
    if gcloud compute tpus tpu-vm describe "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      log_info "TPU VM $TPU_NAME already exists. Skipping creation."
    else
      log_info "Creating TPU VM $TPU_NAME ($TPU_ACCELERATOR_TYPE) in $TPU_ZONE..."
      if [ -n "$DISK_FLAG" ]; then
        gcloud compute tpus tpu-vm create "$TPU_NAME" \
          --zone="$TPU_ZONE" \
          --accelerator-type="$TPU_ACCELERATOR_TYPE" \
          --version="$TPU_VERSION" \
          $DISK_FLAG \
          $PROJECT_FLAG
      else
        gcloud compute tpus tpu-vm create "$TPU_NAME" \
          --zone="$TPU_ZONE" \
          --accelerator-type="$TPU_ACCELERATOR_TYPE" \
          --version="$TPU_VERSION" \
          $PROJECT_FLAG
      fi
      log_info "TPU VM $TPU_NAME created successfully."
    fi
    ;;
  delete)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm delete <name>"; exit 1; fi
    log_info "Deleting TPU VM $TPU_NAME in zone $TPU_ZONE..."
    gcloud compute tpus tpu-vm delete "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG --quiet
    log_info "TPU VM $TPU_NAME deleted."
    if gcloud compute disks describe "${TPU_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      log_info "Deleting attached data disk ${TPU_NAME}-data..."
      gcloud compute disks delete "${TPU_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG --quiet
    fi
    ;;
  start)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm start <name>"; exit 1; fi
    log_info "Starting TPU VM $TPU_NAME in zone $TPU_ZONE..."
    gcloud compute tpus tpu-vm start "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG
    ;;
  stop)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm stop <name>"; exit 1; fi
    log_info "Stopping TPU VM $TPU_NAME in zone $TPU_ZONE..."
    gcloud compute tpus tpu-vm stop "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG
    ;;
  ssh)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm ssh <name> [command]"; exit 1; fi
    shift 2
    DETACHED=""
    FORWARD_PORT=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --detached) DETACHED="true"; shift ;;
        --forward-port) FORWARD_PORT="$2"; shift 2 ;;
        *) break ;;
      esac
    done
    
    SSH_FLAGS=""
    if [ -n "$FORWARD_PORT" ]; then
      SSH_FLAGS="--ssh-flag=-L${FORWARD_PORT}"
      log_info "Forwarding port $FORWARD_PORT..."
    fi
    
    log_info "Connecting to TPU VM $TPU_NAME..."
    if [ $# -gt 0 ]; then
      if [ "$DETACHED" = "true" ]; then
        log_info "Running command in detached tmux session 'ml-session'"
        CMD_STR="tmux new-session -d -s ml-session \"$*\""
        gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG $SSH_FLAGS --command "$CMD_STR"
      else
        gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG $SSH_FLAGS --command "$*"
      fi
    else
      gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG $SSH_FLAGS
    fi
    ;;
  *)
    log_error "Unknown or missing action: $ACTION. Supported: create, delete, start, stop, ssh."
    exit 1
    ;;
esac
