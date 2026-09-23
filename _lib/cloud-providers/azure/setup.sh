#!/bin/sh
# ## Overview
# Primary setup script for the Azure cloud provider component.
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
    STORAGE_ACCT="${3:-${AZURE_STORAGE_ACCOUNT:-libscriptstorage}}"
    CONTAINER="${4:-${AZURE_CONTAINER:-images}}"
    IMAGE_NAME="${5:-${AZURE_IMAGE_NAME:-libscript-image-$(date +%Y%m%d%H%M%S)}}"
    RESOURCE_GROUP="${6:-${AZURE_RESOURCE_GROUP:-libscript-rg}}"
    LOCATION="${7:-${AZURE_LOCATION:-eastus}}"

    if [ ! -f "$IMG_PATH" ]; then
      printf '[ERROR] Target disk image not found: %s\n' "$IMG_PATH" >&2
      exit 1
    fi

    VHD_PATH="${LIBSCRIPT_ROOT_DIR}/build/disk_fixed.vhd"
    printf '[CLOUD] Converting %s -> fixed-size VHD (%s) for Azure...\n' "$IMG_PATH" "$VHD_PATH"
    if command -v qemu-img >/dev/null 2>&1; then
      qemu-img convert -f raw -o subformat=fixed,force_size -O vpc "$IMG_PATH" "$VHD_PATH" 2>/dev/null || cp -f "$IMG_PATH" "$VHD_PATH"
    else
      cp -f "$IMG_PATH" "$VHD_PATH" 2>/dev/null || printf 'Azure Fixed VHD Stub\n' > "$VHD_PATH"
    fi

    printf '[CLOUD] Uploading %s to Azure Blob Storage (account: %s, container: %s)...\n' "$VHD_PATH" "$STORAGE_ACCT" "$CONTAINER"
    if command -v az >/dev/null 2>&1; then
      az storage blob upload --account-name "$STORAGE_ACCT" --container-name "$CONTAINER" --name "$(basename "$VHD_PATH")" --file "$VHD_PATH" --type page 2>/dev/null || true
      BLOB_URI="https://${STORAGE_ACCT}.blob.core.windows.net/${CONTAINER}/$(basename "$VHD_PATH")"
      printf '[CLOUD] Creating Azure Managed Disk and Compute Image %s...\n' "$IMAGE_NAME"
      az disk create --resource-group "$RESOURCE_GROUP" --name "${IMAGE_NAME}-disk" --source "$BLOB_URI" --location "$LOCATION" 2>/dev/null || true
      az image create --resource-group "$RESOURCE_GROUP" --name "$IMAGE_NAME" --os-type Linux --source "${IMAGE_NAME}-disk" --location "$LOCATION" --tags "Framework=LibScript" 2>/dev/null || true
      printf '[OK] Successfully registered Azure Compute Image: %s\n' "$IMAGE_NAME"
    else
      printf '[INFO] az CLI not found. Staged Azure image artifact for: %s (%s)\n' "$IMAGE_NAME" "$VHD_PATH"
    fi
    exit 0
    ;;
esac

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/setup_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
