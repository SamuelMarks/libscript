#!/bin/sh
# ## Overview
# Synthesizes a Google Cloud Marketplace Terraform Solution package (`main.tf`, `variables.tf`,
# `outputs.tf`, `metadata.yaml`, `display.yaml`) referencing Shielded UEFI GCE unikernel images.
#
# ## Usage
# ./cli/commands/marketplace/gcp.sh <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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

OFFER_FILE=''
OUT_DIR=''
STAGE_ONLY=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir=*) OUT_DIR="${1#*=}"; shift ;;
    --stage-only) STAGE_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) [ -z "$OFFER_FILE" ] && OFFER_FILE="$1"; shift ;;
  esac
done

[ -f "$OFFER_FILE" ] || { printf '[ERROR] Valid offer.json required\n' >&2; exit 1; }
OFFER_ID=$(jq -r '.offer_id' "$OFFER_FILE")
OFFER_VER=$(jq -r '.version' "$OFFER_FILE")
OFFER_TITLE=$(jq -r '.product_title' "$OFFER_FILE")
OFFER_SUMMARY=$(jq -r '.summary' "$OFFER_FILE")
GCP_PROJ=$(jq -r '.targets.gcp_marketplace.project_id // "libscript-marketplace-public"' "$OFFER_FILE")
[ -n "$OUT_DIR" ] || OUT_DIR="${LIBSCRIPT_ROOT_DIR}/build/marketplace/${OFFER_ID}/gcp"
mkdir -p "$OUT_DIR"

cat << 'EOF_VAR_TF' > "${OUT_DIR}/variables.tf"
variable "project_id" {
  type        = string
  description = "Target GCP project ID deploying the unikernel constellation."
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "Target GCE zone."
}

variable "network" {
  type        = string
  default     = "default"
  description = "VPC network self-link or name."
}
EOF_VAR_TF

: > "${OUT_DIR}/main.tf.tmp"
jq -c '.appliance_images[]' "$OFFER_FILE" | while IFS= read -r _img; do
  _role=$(printf '%s' "$_img" | jq -r '.role')
  _tf_res=$(printf '%s' "$_role" | tr '-' '_')
  _mach_type=$(printf '%s' "$_img" | jq -r '.default_instance_types.gcp // "n2-standard-2"')
  cat << EOF_RES >> "${OUT_DIR}/main.tf.tmp"
resource "google_compute_instance" "unikernel_${_tf_res}" {
  name         = "${OFFER_ID}-${_role}"
  machine_type = "${_mach_type}"
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "projects/${GCP_PROJ}/global/images/family/${OFFER_ID}-${_role}"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network = var.network
    nic_type = "GVNIC"
  }
}

EOF_RES
done
mv "${OUT_DIR}/main.tf.tmp" "${OUT_DIR}/main.tf"

cat << EOF_OUT_TF > "${OUT_DIR}/outputs.tf"
output "offer_id" {
  value       = "${OFFER_ID}"
  description = "Deployed Google Cloud Marketplace unikernel solution identifier."
}
EOF_OUT_TF

cat << EOF_META > "${OUT_DIR}/metadata.yaml"
apiVersion: blueprints.cloud.google.com/v1alpha1
kind: BlueprintMetadata
metadata:
  name: ${OFFER_ID}
spec:
  info:
    title: "${OFFER_TITLE}"
    version: "${OFFER_VER}"
    description:
      tagline: "${OFFER_SUMMARY}"
EOF_META

cat << EOF_DISP > "${OUT_DIR}/display.yaml"
apiVersion: blueprints.cloud.google.com/v1alpha1
kind: BlueprintDisplay
metadata:
  name: ${OFFER_ID}-display
spec:
  input:
    variables:
      project_id:
        name: project_id
        title: Project ID
      zone:
        name: zone
        title: Deployment Zone
EOF_DISP

if [ "$STAGE_ONLY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && command -v mpdev >/dev/null 2>&1; then
  mpdev verify --filename="${OUT_DIR}/metadata.yaml"
fi

printf '[OK] GCP Marketplace Terraform Blueprint synthesized at %s\n' "$OUT_DIR"
