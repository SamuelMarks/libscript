#!/bin/sh
# ## Overview
# Uploads a `disk.raw.tar.gz` sparse archive to Google Cloud Storage and registers a Shielded GCE
# image with `UEFI_COMPATIBLE`, `GVNIC`, and `VIRTIO_SCSI_MULTIQUEUE`.
#
# ## Usage
# ./infrastructure/resources/image-import/gcp_import.sh --disk=<disk.raw.tar.gz> --bucket=<gcs_bucket> --project=<gcp_proj> --name=<img_name> [--out=<receipt.json>] [--dry-run]

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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

DISK_PATH=''
BUCKET=''
PROJECT_ID=''
IMG_NAME=''
ARCH_VAL="${IMAGE_IMPORT_ARCH:-X86_64}"
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --bucket=*) BUCKET="${1#*=}"; shift ;;
    --project=*) PROJECT_ID="${1#*=}"; shift ;;
    --name=*) IMG_NAME="${1#*=}"; shift ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    *) shift ;;
  esac
done

case "$ARCH_VAL" in
  x86_64|X86_64) ARCH_VAL='X86_64' ;;
  arm64|aarch64|ARM64) ARCH_VAL='ARM64' ;;
esac

[ -n "$DISK_PATH" ] && [ -f "$DISK_PATH" ] || { printf '[ERROR] --disk=<existing_tar_gz> required\n' >&2; exit 1; }
[ -n "$BUCKET" ] || { printf '[ERROR] --bucket=<gcs_bucket> required\n' >&2; exit 1; }
[ -n "$PROJECT_ID" ] || { printf '[ERROR] --project=<gcp_project> required\n' >&2; exit 1; }
[ -n "$IMG_NAME" ] || { printf '[ERROR] --name=<gce_image_name> required\n' >&2; exit 1; }

# ## compute_sha256
# Computes a portable SHA-256 hex digest of a file.
compute_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
CLEAN_NAME=$(printf '%s-%s' "$IMG_NAME" "$SHORT_SHA" | tr '[:upper:]_.' '[:lower:]--')
GCS_URI="gs://${BUCKET}/libscript-images/${CLEAN_NAME}.disk.raw.tar.gz"
SELF_LINK="projects/${PROJECT_ID}/global/images/${CLEAN_NAME}"
[ -n "$OUT_RECEIPT" ] || OUT_RECEIPT="${DISK_PATH}.gcp-image-receipt.json"

if [ -f "$OUT_RECEIPT" ] && jq -e --arg d "$DIGEST" '.sha256 == $d' "$OUT_RECEIPT" >/dev/null 2>&1; then
  printf '[SKIP] GCP Compute Engine image already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_RECEIPT"
  exit 0
fi

if [ "$DRY_RUN" != "1" ]; then
  if ! gcloud compute images describe "$CLEAN_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud storage cp "$DISK_PATH" "$GCS_URI" --project="$PROJECT_ID"
    gcloud compute images create "$CLEAN_NAME" \
      --project="$PROJECT_ID" \
      --source-uri="$GCS_URI" \
      --architecture="$ARCH_VAL" \
      --guest-os-features="UEFI_COMPATIBLE,GVNIC,VIRTIO_SCSI_MULTIQUEUE" \
      --labels="libscript_digest=${SHORT_SHA}"
  fi
fi

mkdir -p "$(dirname -- "$OUT_RECEIPT")"
cat << EOF > "${OUT_RECEIPT}.tmp"
{
  "cloud": "gcp",
  "image_self_link": "${SELF_LINK}",
  "image_name": "${CLEAN_NAME}",
  "project_id": "${PROJECT_ID}",
  "architecture": "${ARCH_VAL}",
  "guest_os_features": ["UEFI_COMPATIBLE", "GVNIC", "VIRTIO_SCSI_MULTIQUEUE"],
  "gcs_uri": "${GCS_URI}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] GCP Compute Engine image receipt written: %s (%s)\n' "$OUT_RECEIPT" "$CLEAN_NAME"
