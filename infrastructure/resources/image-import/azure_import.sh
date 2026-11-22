#!/bin/sh
# ## Overview
# Verifies 1 MiB VHD modulus alignment, uploads as an Azure PageBlob, and registers a Hyper-V Gen2
# Azure Compute Gallery image version idempotently.
#
# ## Usage
# ./infrastructure/resources/image-import/azure_import.sh --disk=<disk.vhd> --account=<storage_acct> --gallery=<sig> --rg=<rg> --name=<img_def> [--version=<1.0.0>] [--out=<receipt.json>] [--dry-run]

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
ACCOUNT=''
GALLERY=''
RG='libscript-marketplace-rg'
IMG_NAME=''
IMG_VER='1.0.0'
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --account=*) ACCOUNT="${1#*=}"; shift ;;
    --gallery=*) GALLERY="${1#*=}"; shift ;;
    --rg=*) RG="${1#*=}"; shift ;;
    --name=*) IMG_NAME="${1#*=}"; shift ;;
    --version=*) IMG_VER="${1#*=}"; shift ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    *) shift ;;
  esac
done

[ -n "$DISK_PATH" ] && [ -f "$DISK_PATH" ] || { printf '[ERROR] --disk=<existing_vhd> required\n' >&2; exit 1; }
[ -n "$ACCOUNT" ] || { printf '[ERROR] --account=<storage_account> required\n' >&2; exit 1; }
[ -n "$GALLERY" ] || { printf '[ERROR] --gallery=<compute_gallery> required\n' >&2; exit 1; }
[ -n "$IMG_NAME" ] || { printf '[ERROR] --name=<image_definition> required\n' >&2; exit 1; }

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

FILE_BYTES=$(wc -c < "$DISK_PATH" | tr -d ' ')
REM_MIB=$((FILE_BYTES % 1048576))
if [ "$REM_MIB" -ne 0 ] && [ "$REM_MIB" -ne 512 ]; then
  printf '[ERROR] Azure VHD %s (%s bytes) violates 1 MiB alignment (+512-byte fixed footer).\n' "$DISK_PATH" "$FILE_BYTES" >&2
  exit 1
fi

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
BLOB_URI="https://${ACCOUNT}.blob.core.windows.net/vhds/${IMG_NAME}-${SHORT_SHA}.vhd"
SIG_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${RG}/providers/Microsoft.Compute/galleries/${GALLERY}/images/${IMG_NAME}/versions/${IMG_VER}"
[ -n "$OUT_RECEIPT" ] || OUT_RECEIPT="${DISK_PATH}.azure-sig-receipt.json"

if [ -f "$OUT_RECEIPT" ] && jq -e --arg d "$DIGEST" '.sha256 == $d' "$OUT_RECEIPT" >/dev/null 2>&1; then
  printf '[SKIP] Azure Compute Gallery image already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_RECEIPT"
  exit 0
fi

if [ "$DRY_RUN" != "1" ]; then
  az storage blob upload --account-name "$ACCOUNT" --container-name vhds --type page \
    --file "$DISK_PATH" --name "${IMG_NAME}-${SHORT_SHA}.vhd" --overwrite true
  az sig image-definition show --resource-group "$RG" --gallery-name "$GALLERY" --gallery-image-definition "$IMG_NAME" >/dev/null 2>&1 || \
    az sig image-definition create --resource-group "$RG" --gallery-name "$GALLERY" \
      --gallery-image-definition "$IMG_NAME" --publisher libscript --offer "$IMG_NAME" --sku gen2-uefi \
      --os-type Linux --os-state Generalized --hyper-v-generation V2 --features SecurityType=TrustedLaunch
  SIG_ID=$(az sig image-version create --resource-group "$RG" --gallery-name "$GALLERY" \
    --gallery-image-definition "$IMG_NAME" --gallery-image-version "$IMG_VER" \
    --os-vhd-uri "$BLOB_URI" --os-vhd-storage-account "$ACCOUNT" \
    --tags "LibScriptDigest=${DIGEST}" --query 'id' -o tsv)
fi

mkdir -p "$(dirname -- "$OUT_RECEIPT")"
cat << EOF > "${OUT_RECEIPT}.tmp"
{
  "cloud": "azure",
  "gallery_image_version_id": "${SIG_ID}",
  "resource_group": "${RG}",
  "gallery": "${GALLERY}",
  "image_definition": "${IMG_NAME}",
  "version": "${IMG_VER}",
  "hyper_v_generation": "V2",
  "blob_uri": "${BLOB_URI}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] Azure Compute Gallery receipt written: %s\n' "$OUT_RECEIPT"
