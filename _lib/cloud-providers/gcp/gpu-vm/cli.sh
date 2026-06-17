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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

# Walk up to find root
_root="$SCRIPT_DIR"
while [ ! -f "$_root/ROOT" ] && [ "$_root" != "/" ]; do
    _root=$(dirname "$_root")
done
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$_root}"

set -feu

# Ensure base variables are loaded if available
if [ -f "${SCRIPT_DIR}/../../_common/log.sh" ]; then
  . "${SCRIPT_DIR}/../../_common/log.sh"
else
  log_info() { echo "[INFO] $1"; }
  log_warn() { echo "[WARN] $1"; }
  log_error() { echo "[ERROR] $1" >&2; }
fi

ACTION="${1:-}"
shift || true
GPU_NAME="${1:-}"
if [ -n "$GPU_NAME" ]; then
  shift || true
fi

# Load variables (would normally come from libscript env setup)
GPU_ZONE="${GPU_ZONE:-}"
if [ -z "$GPU_ZONE" ]; then
  log_error "GPU_ZONE must be explicitly specified (e.g., us-central1-a)."
  exit 1
fi

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
if [ -z "$GCP_PROJECT_ID" ]; then
  log_error "GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning."
  exit 1
fi

GPU_MACHINE_TYPE="${GPU_MACHINE_TYPE:-n1-standard-4}"
GPU_ACCELERATOR="${GPU_ACCELERATOR:-type=nvidia-tesla-t4,count=1}"
GPU_IMAGE_PROJECT="${GPU_IMAGE_PROJECT:-deeplearning-platform-release}"
GPU_IMAGE_FAMILY="${GPU_IMAGE_FAMILY:-common-cu121-debian-11}"

GPU_DATA_DISK_SIZE="${GPU_DATA_DISK_SIZE:-}"
GPU_DATA_DISK_TYPE="${GPU_DATA_DISK_TYPE:-pd-balanced}"

PROJECT_FLAG="--project=${GCP_PROJECT_ID}"

case "$ACTION" in
  create)
    if [ -z "$GPU_NAME" ]; then log_error "Usage: gpu-vm create <name>"; exit 1; fi
    
    DISK_FLAG=""
    if [ -n "$GPU_DATA_DISK_SIZE" ]; then
      DISK_FLAG="--disk=name=${GPU_NAME}-data,mode=rw,boot=no,device-name=${GPU_NAME}-data"
      # Check and create disk if it doesn't exist
      if ! gcloud compute disks describe "${GPU_NAME}-data" --zone="$GPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
        log_info "Creating persistent data disk ${GPU_NAME}-data (${GPU_DATA_DISK_SIZE}GB, ${GPU_DATA_DISK_TYPE})..."
        gcloud compute disks create "${GPU_NAME}-data" \
          --size="${GPU_DATA_DISK_SIZE}GB" \
          --type="${GPU_DATA_DISK_TYPE}" \
          --zone="$GPU_ZONE" \
          $PROJECT_FLAG
      else
        log_info "Data disk ${GPU_NAME}-data already exists."
      fi
    fi

    log_info "Checking if GPU VM $GPU_NAME exists in zone $GPU_ZONE..."
    if gcloud compute instances describe "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      log_info "GPU VM $GPU_NAME already exists. Skipping creation."
    else
      log_info "Creating GPU VM $GPU_NAME ($GPU_MACHINE_TYPE, $GPU_ACCELERATOR) in $GPU_ZONE..."
      gcloud compute instances create "$GPU_NAME" \
        --zone="$GPU_ZONE" \
        --machine-type="$GPU_MACHINE_TYPE" \
        --accelerator="$GPU_ACCELERATOR" \
        --image-project="$GPU_IMAGE_PROJECT" \
        --image-family="$GPU_IMAGE_FAMILY" \
        --maintenance-policy=TERMINATE \
        $DISK_FLAG \
        $PROJECT_FLAG
      log_info "GPU VM $GPU_NAME created successfully."
    fi
    ;;
  delete)
    if [ -z "$GPU_NAME" ]; then log_error "Usage: gpu-vm delete <name>"; exit 1; fi
    log_info "Deleting GPU VM $GPU_NAME in zone $GPU_ZONE..."
    gcloud compute instances delete "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG --quiet
    log_info "GPU VM $GPU_NAME deleted."
    if gcloud compute disks describe "${GPU_NAME}-data" --zone="$GPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      log_info "Deleting attached data disk ${GPU_NAME}-data..."
      gcloud compute disks delete "${GPU_NAME}-data" --zone="$GPU_ZONE" $PROJECT_FLAG --quiet
    fi
    ;;
  start)
    if [ -z "$GPU_NAME" ]; then log_error "Usage: gpu-vm start <name>"; exit 1; fi
    log_info "Starting GPU VM $GPU_NAME in zone $GPU_ZONE..."
    gcloud compute instances start "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG
    ;;
  stop)
    if [ -z "$GPU_NAME" ]; then log_error "Usage: gpu-vm stop <name>"; exit 1; fi
    log_info "Stopping GPU VM $GPU_NAME in zone $GPU_ZONE..."
    gcloud compute instances stop "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG
    ;;
  ssh)
    if [ -z "$GPU_NAME" ]; then log_error "Usage: gpu-vm ssh <name> [--detached] [--forward-port <local>:<remote>] [command]"; exit 1; fi
    
    DETACHED="false"
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

    if [ $# -gt 0 ]; then
      if [ "$DETACHED" = "true" ]; then
        log_info "Running command in detached tmux session 'ml-session'"
        CMD_STR="tmux new-session -d -s ml-session \"$*\""
        gcloud compute ssh "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG $SSH_FLAGS --command "$CMD_STR"
      else
        gcloud compute ssh "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG $SSH_FLAGS --command "$*"
      fi
    else
      gcloud compute ssh "$GPU_NAME" --zone="$GPU_ZONE" $PROJECT_FLAG $SSH_FLAGS
    fi
    ;;
  *)
    log_error "Unknown or missing action: $ACTION. Supported: create, delete, start, stop, ssh."
    exit 1
    ;;
esac
