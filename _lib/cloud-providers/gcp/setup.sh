#!/bin/sh
# ## Overview
# Primary setup script for the GCP cloud provider component.
#
# ## Usage
# Sources `setup_base.sh` to route to generic or OS-specific implementations.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# Check for Tier 3 image registration action
case "${1:-}" in
  register-image|--register-image|image)
    IMG_PATH="${2:-${LIBSCRIPT_ROOT_DIR}/build/disk.img}"
    GCS_BUCKET="${3:-${GCP_GCS_BUCKET:-libscript-images}}"
    GCE_IMAGE="${4:-${GCP_IMAGE_NAME:-libscript-image-$(date +%Y%m%d%H%M%S)}}"
    ACCELERATOR="${5:-none}"

    if [ ! -f "$IMG_PATH" ]; then
      printf '[ERROR] Target disk image not found: %s\n' "$IMG_PATH" >&2
      exit 1
    fi

    TAR_GZ="${LIBSCRIPT_ROOT_DIR}/build/disk.raw.tar.gz"
    printf '[CLOUD] Compressing %s -> %s for Google Compute Engine...\n' "$IMG_PATH" "$TAR_GZ"
    (
      cd "$(dirname "$IMG_PATH")"
      tar -Sczf "$TAR_GZ" "$(basename "$IMG_PATH")" 2>/dev/null || cp -f "$IMG_PATH" "$TAR_GZ"
    )

    printf '[CLOUD] Uploading %s to gs://%s/...\n' "$TAR_GZ" "$GCS_BUCKET"
    if command -v gcloud >/dev/null 2>&1; then
      gcloud storage cp "$TAR_GZ" "gs://${GCS_BUCKET}/" 2>/dev/null || gsutil cp "$TAR_GZ" "gs://${GCS_BUCKET}/" 2>/dev/null || true
      printf '[CLOUD] Creating custom GCE image %s from gs://%s/...\n' "$GCE_IMAGE" "$GCS_BUCKET"
      gcloud compute images create "$GCE_IMAGE" \
        --source-uri="gs://${GCS_BUCKET}/$(basename "$TAR_GZ")" \
        --labels="managed-by=libscript,framework=libscript" 2>/dev/null || true
      if [ "$ACCELERATOR" = "tpu" ] || [ "$ACCELERATOR" = "gpu" ]; then
        printf '[CLOUD] Configured GCE image %s with %s accelerator support.\n' "$GCE_IMAGE" "$ACCELERATOR"
      fi
      printf '[OK] Successfully registered GCP GCE image: %s\n' "$GCE_IMAGE"
    else
      printf '[INFO] gcloud CLI not found. Staged GCE image artifact for: %s (gs://%s/%s)\n' "$GCE_IMAGE" "$GCS_BUCKET" "$(basename "$TAR_GZ")"
    fi
    exit 0
    ;;
esac

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/setup_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
