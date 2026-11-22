#!/bin/sh
# ## Overview
# Synthesizes an Azure Marketplace Managed Application bundle and Partner Center offer payload.
#
# ## Usage
# ./infrastructure/marketplace/azure.sh <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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
[ -n "$OUT_DIR" ] || OUT_DIR="${LIBSCRIPT_ROOT_DIR}/build/infrastructure/marketplace/${OFFER_ID}/azure"
mkdir -p "${OUT_DIR}/pkg"

jq '
  . as $o
  | {
      "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      contentVersion: "1.0.0.0",
      parameters: {
        location: { type: "string", defaultValue: "[resourceGroup().location]" }
      },
      resources: [
        $o.appliance_images[] | {
          type: "Microsoft.Compute/virtualMachines",
          apiVersion: "2023-09-01",
          name: ($o.offer_id + "-" + .role),
          location: "[parameters('\''location'\'')]",
          properties: {
            hardwareProfile: { vmSize: (.default_instance_types.azure // "Standard_D2s_v5") },
            storageProfile: {
              imageReference: {
                id: ("/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/" + ($o.targets.azure_marketplace.resource_group // "libscript-rg") + "/providers/Microsoft.Compute/galleries/" + ($o.targets.azure_marketplace.compute_gallery // "libscript_sig") + "/images/" + .role + "/versions/latest")
              }
            }
          }
        }
      ]
    }
' "$OFFER_FILE" > "${OUT_DIR}/pkg/mainTemplate.json.tmp"
mv "${OUT_DIR}/pkg/mainTemplate.json.tmp" "${OUT_DIR}/pkg/mainTemplate.json"

jq '
  {
    "$schema": "https://schema.management.azure.com/schemas/0.1.2-preview/CreateUIDefinition.MultiVm.json#",
    handler: "Microsoft.Azure.CreateUIDef",
    version: "0.1.2-preview",
    parameters: {
      basics: [{ name: "applianceTitle", type: "Microsoft.Common.TextBlock", options: { text: .product_title } }],
      steps: [],
      outputs: { location: "[location()]" }
    }
  }
' "$OFFER_FILE" > "${OUT_DIR}/pkg/createUiDefinition.json"

# shellcheck disable=SC2016
printf '%s\n' '{"$schema":"https://schema.management.azure.com/schemas/viewdefinition/0.0.1-preview/ViewDefinition.json#","contentVersion":"0.0.0.1","views":[{"kind":"Overview","properties":{"header":"LibScript Unikernel Constellation","description":"Managed Multi-Unikernel Appliance"}}]}' > "${OUT_DIR}/pkg/viewDefinition.json"

jq '
  {
    resourceType: "AzureApplication",
    id: .offer_id,
    alias: .product_title,
    planId: (.targets.azure_marketplace.plan_id // (.offer_id + "-plan")),
    version: .version,
    pricingModel: .pricing.model
  }
' "$OFFER_FILE" > "${OUT_DIR}/partner-center-offer.json"

(cd "${OUT_DIR}/pkg" && tar -czf "${OUT_DIR}/managed-app-package.tar.gz" mainTemplate.json createUiDefinition.json viewDefinition.json)

if [ "$STAGE_ONLY" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && command -v az >/dev/null 2>&1; then
  az partnercenter marketplace offer show --id "$OFFER_ID" >/dev/null 2>&1 || \
    az partnercenter marketplace offer create --id "$OFFER_ID" --alias "$(jq -r '.product_title' "$OFFER_FILE")" --type AzureApplication
fi

printf '[OK] Azure Marketplace Managed Application bundle synthesized at %s\n' "$OUT_DIR"
