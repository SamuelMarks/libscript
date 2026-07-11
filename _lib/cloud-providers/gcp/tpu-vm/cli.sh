#!/bin/sh
# ## Overview
# Command-line interface for managing GCP Cloud TPU VMs.
#
# ## Usage
# Provides commands to create, delete, start, stop, and SSH into Cloud TPU VMs.
# Run `libscript.sh gcp/tpu-vm <action> [args...]`.


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

# Ensure gcloud is available
if ! command -v gcloud >/dev/null 2>&1; then
  log_error "gcloud not found in PATH. Please install the gcp/cli component first."
  exit 1
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <action> [args...]"
  printf '%s\n' "See README.md for details."
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

TPU_SCHEDULING_TYPE="${TPU_SCHEDULING_TYPE:-on-demand}"
SCHEDULING_FLAG=""
if [ "$TPU_SCHEDULING_TYPE" = "spot" ]; then
  SCHEDULING_FLAG="--spot"
elif [ "$TPU_SCHEDULING_TYPE" = "preemptible" ]; then
  SCHEDULING_FLAG="--preemptible"
fi


TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-}"
TPU_DATA_DISK_TYPE="${TPU_DATA_DISK_TYPE:-pd-balanced}"

TPU_COUNT="${TPU_COUNT:-1}"

PROJECT_FLAG="--project=${GCP_PROJECT_ID}"

case "$ACTION" in
  create)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm create <name>"; exit 1; fi
    i=1
    while [ "$i" -le "$TPU_COUNT" ]; do
      INSTANCE_NAME="$TPU_NAME"
      if [ "$TPU_COUNT" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      
      DISK_FLAG=""
      if [ -n "$TPU_DATA_DISK_SIZE" ]; then
        DISK_FLAG="--data-disk=source=projects/${GCP_PROJECT_ID}/zones/${TPU_ZONE}/disks/${INSTANCE_NAME}-data,mode=read-write"
        if ! gcloud compute disks describe "${INSTANCE_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
          log_info "Creating persistent data disk ${INSTANCE_NAME}-data (${TPU_DATA_DISK_SIZE}GB, ${TPU_DATA_DISK_TYPE})..."
          
          if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
            # shellcheck disable=SC1091
            . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
          fi
          TAGS_ARG="$(libscript_format_tags gcp)"

          # shellcheck disable=SC2086
          gcloud compute disks create "${INSTANCE_NAME}-data" \
            --size="${TPU_DATA_DISK_SIZE}GB" \
            --type="${TPU_DATA_DISK_TYPE}" \
            --zone="$TPU_ZONE" \
            $PROJECT_FLAG $TAGS_ARG
        else
          log_info "Data disk ${INSTANCE_NAME}-data already exists."
        fi
      fi

      NETWORK_FLAG=""
      if [ -n "${TPU_NETWORK:-}" ]; then NETWORK_FLAG="--network=$TPU_NETWORK"; fi
      if [ -n "${TPU_SUBNETWORK:-}" ]; then NETWORK_FLAG="$NETWORK_FLAG --subnetwork=$TPU_SUBNETWORK"; fi
      
      if [ "${TPU_USE_QUEUED_RESOURCE:-false}" = "true" ]; then
        log_info "Checking if TPU Queued Resource ${INSTANCE_NAME}-qr exists in zone $TPU_ZONE..."
        if gcloud alpha compute tpus queued-resources describe "${INSTANCE_NAME}-qr" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
          log_info "TPU Queued Resource ${INSTANCE_NAME}-qr already exists. Skipping creation."
        else
          log_info "Creating TPU Queued Resource ${INSTANCE_NAME}-qr ($TPU_ACCELERATOR_TYPE) in $TPU_ZONE..."
          
          if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
            # shellcheck disable=SC1091
            . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
          fi
          TAGS_ARG="$(libscript_format_tags gcp)"

          # shellcheck disable=SC2086
          if ! gcloud alpha compute tpus queued-resources create "${INSTANCE_NAME}-qr" \
            --node-id="$INSTANCE_NAME" \
            --zone="$TPU_ZONE" \
            --accelerator-type="$TPU_ACCELERATOR_TYPE" \
            --runtime-version="$TPU_VERSION" \
            $SCHEDULING_FLAG \
            $DISK_FLAG \
            $NETWORK_FLAG \
            $PROJECT_FLAG $TAGS_ARG; then
            log_error "Queued Resource Provisioning failed. Check TFRC quota availability."
            exit 1
          fi
          log_info "TPU Queued Resource ${INSTANCE_NAME}-qr submitted successfully."
        fi
      else
        log_info "Checking if TPU VM $INSTANCE_NAME exists in zone $TPU_ZONE..."
        if gcloud compute tpus tpu-vm describe "$INSTANCE_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
          log_info "TPU VM $INSTANCE_NAME already exists. Skipping creation."
        else
          log_info "Creating TPU VM $INSTANCE_NAME ($TPU_ACCELERATOR_TYPE) in $TPU_ZONE..."
          
          if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
            # shellcheck disable=SC1091
            . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
          fi
          TAGS_ARG="$(libscript_format_tags gcp)"

          # shellcheck disable=SC2086
          if ! gcloud compute tpus tpu-vm create "$INSTANCE_NAME" \
            --zone="$TPU_ZONE" \
            --accelerator-type="$TPU_ACCELERATOR_TYPE" \
            --version="$TPU_VERSION" \
            $SCHEDULING_FLAG \
            $DISK_FLAG \
            $NETWORK_FLAG \
            $PROJECT_FLAG $TAGS_ARG; then
            log_error "Provisioning failed. If using spot/preemptible, check TFRC quota availability."
            exit 1
          fi
          log_info "TPU VM $INSTANCE_NAME created successfully."
        fi
      fi
      i=$((i + 1))
    done
    ;;
  delete)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm delete <name> [--all]"; exit 1; fi
    shift 2
    ALL_FLAG=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG="true"; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="$TPU_COUNT"
    if [ "$ALL_FLAG" != "true" ]; then LIMIT=1; fi
    while [ "$i" -le "$LIMIT" ]; do
      INSTANCE_NAME="$TPU_NAME"
      if [ "$LIMIT" -gt 1 ] && [ "$TPU_COUNT" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi

      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
        # shellcheck disable=SC1091
        . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
      fi

      log_info "Deleting TPU VM $INSTANCE_NAME in zone $TPU_ZONE..."
      if libscript_verify_managed gcp tpu-vm "$INSTANCE_NAME" "$TPU_ZONE"; then
        gcloud compute tpus tpu-vm delete "$INSTANCE_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG --quiet || true
      fi

      if [ "${TPU_USE_QUEUED_RESOURCE:-false}" = "true" ]; then
        log_info "Deleting queued resource ${INSTANCE_NAME}-qr..."
        if libscript_verify_managed gcp qr "${INSTANCE_NAME}-qr" "$TPU_ZONE"; then
          gcloud alpha compute tpus queued-resources delete "${INSTANCE_NAME}-qr" --zone="$TPU_ZONE" $PROJECT_FLAG --quiet --force || true
        fi
      fi

      if gcloud compute disks describe "${INSTANCE_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
        log_info "Deleting attached data disk ${INSTANCE_NAME}-data..."
        if libscript_verify_managed gcp volume "${INSTANCE_NAME}-data" "$TPU_ZONE"; then
          gcloud compute disks delete "${INSTANCE_NAME}-data" --zone="$TPU_ZONE" $PROJECT_FLAG --quiet || true
        fi
      fi
      i=$((i + 1))
    done
    ;;
  start)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm start <name> [--all]"; exit 1; fi
    shift 2
    ALL_FLAG=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG="true"; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="$TPU_COUNT"
    if [ "$ALL_FLAG" != "true" ]; then LIMIT=1; fi
    while [ "$i" -le "$LIMIT" ]; do
      INSTANCE_NAME="$TPU_NAME"
      if [ "$LIMIT" -gt 1 ] && [ "$TPU_COUNT" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Starting TPU VM $INSTANCE_NAME in zone $TPU_ZONE..."
      gcloud compute tpus tpu-vm start "$INSTANCE_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG || true
      i=$((i + 1))
    done
    ;;
  stop)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm stop <name> [--all]"; exit 1; fi
    shift 2
    ALL_FLAG=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG="true"; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="$TPU_COUNT"
    if [ "$ALL_FLAG" != "true" ]; then LIMIT=1; fi
    while [ "$i" -le "$LIMIT" ]; do
      INSTANCE_NAME="$TPU_NAME"
      if [ "$LIMIT" -gt 1 ] && [ "$TPU_COUNT" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Stopping TPU VM $INSTANCE_NAME in zone $TPU_ZONE..."
      gcloud compute tpus tpu-vm stop "$INSTANCE_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG || true
      i=$((i + 1))
    done
    ;;
  status)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm status <name> [--all]"; exit 1; fi
    shift 2
    ALL_FLAG=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) ALL_FLAG="true"; shift ;;
        *) shift ;;
      esac
    done
    i=1
    LIMIT="$TPU_COUNT"
    if [ "$ALL_FLAG" != "true" ]; then LIMIT=1; fi
    while [ "$i" -le "$LIMIT" ]; do
      INSTANCE_NAME="$TPU_NAME"
      if [ "$LIMIT" -gt 1 ] && [ "$TPU_COUNT" -gt 1 ]; then
        INSTANCE_NAME="${TPU_NAME}-${i}"
      fi
      log_info "Status for TPU VM $INSTANCE_NAME in zone $TPU_ZONE..."
      if [ "${TPU_USE_QUEUED_RESOURCE:-false}" = "true" ]; then
        gcloud alpha compute tpus queued-resources describe "${INSTANCE_NAME}-qr" --zone="$TPU_ZONE" $PROJECT_FLAG || true
      else
        gcloud compute tpus tpu-vm describe "$INSTANCE_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG || true
      fi
      i=$((i + 1))
    done
    ;;
  profile)
    # Usage: tpu-vm profile <name> [--port 9012] [--duration 1000]
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm profile <name> [--port 9012] [--duration 1000]"; exit 1; fi
    shift 2
    PORT="9012"
    DURATION="1000"
    while [ $# -gt 0 ]; do
      case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    
    log_info "Initiating capture_tpu_profile session on $TPU_NAME in $TPU_ZONE..."
    
    # We must tunnel into the TPU VM because the profiler port is usually not exposed externally
    gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$TPU_ZONE" $PROJECT_FLAG --worker=all --command="capture_tpu_profile --tpu=\$HOSTNAME --profiler_port=$PORT --duration_ms=$DURATION --logdir=/tmp/tpu_profile"
    ;;
  scp)
    # Usage: tpu-vm scp <name> <src> <dest> [--all-workers]
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"; exit 1; fi
    shift 2
    ALL_WORKERS=""
    SRC=""
    DEST=""
    while [ $# -gt 0 ]; do
      case "$1" in
        *) 
          if [ -z "$SRC" ]; then SRC="$1"
          elif [ -z "$DEST" ]; then DEST="$1"
          else log_error "Too many arguments for scp"; exit 1
          fi
          shift
          ;;
      esac
    done
    if [ -z "$SRC" ] || [ -z "$DEST" ]; then
      log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"
      exit 1
    fi
    SCP_FLAGS=""
    if [ "$ALL_WORKERS" = "true" ]; then
      SCP_FLAGS="--worker=all"
    fi
    log_info "Copying files for TPU VM $TPU_NAME..."
    # if DEST does not contain colon, assume it is remote
    if printf '%s\n' "$DEST" | grep -q ":"; then
      gcloud compute tpus tpu-vm scp $SCP_FLAGS "$SRC" "$DEST" --zone="$TPU_ZONE" $PROJECT_FLAG
    elif printf '%s\n' "$SRC" | grep -q ":"; then
      gcloud compute tpus tpu-vm scp $SCP_FLAGS "$SRC" "$DEST" --zone="$TPU_ZONE" $PROJECT_FLAG
    else
      # Neither has colon, assume local to remote
      gcloud compute tpus tpu-vm scp $SCP_FLAGS "$SRC" "${TPU_NAME}:${DEST}" --zone="$TPU_ZONE" $PROJECT_FLAG
    fi
    ;;


  ssh)
    if [ -z "$TPU_NAME" ]; then log_error "Usage: tpu-vm ssh <name> [command]"; exit 1; fi
    shift 2
    DETACHED=""
    ALL_WORKERS=""

    FORWARD_PORT=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --detached) DETACHED="true"; shift ;;
        --forward-port) FORWARD_PORT="$2"; shift 2 ;;
        --all-workers) ALL_WORKERS="true"; shift ;;
        *) break ;;
      esac
    done

    
    SSH_FLAGS=""
    if [ "$ALL_WORKERS" = "true" ]; then
      SSH_FLAGS="$SSH_FLAGS --worker=all"
    fi

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
    log_error "Unknown or missing action: $ACTION. Supported: create, delete, start, stop, ssh, scp, status."
    exit 1
    ;;
esac

