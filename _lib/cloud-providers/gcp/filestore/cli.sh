#!/bin/sh
# ## Overview
# CLI interface for GCP Filestore instances.
#
# ## Usage
# ./libscript.sh gcp/filestore [create|delete] <name>
#
# ## Operations
# - `create <name>`: Create a Filestore instance.
# - `delete <name>`: Delete a Filestore instance.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../../.." && pwd)}"
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

ACTION="${1:-}"

export GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
export FILESTORE_ZONE="${FILESTORE_ZONE:-}"
export FILESTORE_TIER="${FILESTORE_TIER:-BASIC_HDD}"
export FILESTORE_CAPACITY_GB="${FILESTORE_CAPACITY_GB:-1024}"
export FILESTORE_NETWORK="${FILESTORE_NETWORK:-default}"

PROJECT_FLAG=""
if [ -n "$GCP_PROJECT_ID" ]; then PROJECT_FLAG="--project=$GCP_PROJECT_ID"; fi

case "$ACTION" in
  create)
    INSTANCE_NAME="${2:-}"
    if [ -z "$INSTANCE_NAME" ]; then log_error "Usage: filestore create <name>"; exit 1; fi
    log_info "Creating GCP Filestore $INSTANCE_NAME in $FILESTORE_ZONE..."
    
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
      # shellcheck disable=SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
    fi
    TAGS_ARG="$(libscript_format_tags gcp)"
    
    if gcloud filestore instances describe "$INSTANCE_NAME" --zone="$FILESTORE_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      log_info "Filestore '$INSTANCE_NAME' already exists in $FILESTORE_ZONE."
    else
      # shellcheck disable=SC2086
      gcloud filestore instances create "$INSTANCE_NAME" \
        --zone="$FILESTORE_ZONE" \
        --tier="$FILESTORE_TIER" \
        --file-share="name=vol1,capacity=${FILESTORE_CAPACITY_GB}GB" \
        --network="name=$FILESTORE_NETWORK" \
        $PROJECT_FLAG $TAGS_ARG
    fi
    ;;
  delete)
    INSTANCE_NAME="${2:-}"
    if [ -z "$INSTANCE_NAME" ]; then log_error "Usage: filestore delete <name>"; exit 1; fi
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh" ]; then
      # shellcheck disable=SC1091
      . "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
    fi
    libscript_verify_managed gcp filestore "$INSTANCE_NAME" "$FILESTORE_ZONE" || exit 1
    log_info "Deleting GCP Filestore $INSTANCE_NAME in $FILESTORE_ZONE..."
    if gcloud filestore instances describe "$INSTANCE_NAME" --zone="$FILESTORE_ZONE" $PROJECT_FLAG >/dev/null 2>&1; then
      gcloud filestore instances delete "$INSTANCE_NAME" --zone="$FILESTORE_ZONE" --quiet $PROJECT_FLAG
    else
      log_info "Filestore '$INSTANCE_NAME' already deleted or not found."
    fi
    ;;
  *)
    log_error "Unknown action: $ACTION"
    exit 1
    ;;
esac
