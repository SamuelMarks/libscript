#!/bin/sh
# ## Overview
# Multicloud marketplace orchestrator (`libscript publish-marketplace`) staging UEFI unikernels, SBOMs, and AWS/Azure/GCP offers.
#
# ## Usage
# ./infrastructure/marketplace/publish.sh <offer.json> [--clouds=aws,azure,gcp] [--out-dir=<dir>] [--stage-only] [--dry-run] [--allow-stub-sdk]

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
CLOUDS_CSV='aws,azure,gcp'
OUT_DIR=''
STAGE_ONLY=0
DRY_RUN=0
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      printf '%s\n' 'Usage: libscript.sh publish-marketplace <offer.json> [--clouds=aws,azure,gcp] [--out-dir=<dir>] [--stage-only] [--dry-run] [--allow-stub-sdk]'
      exit 0
      ;;
    --clouds=*) CLOUDS_CSV="${1#*=}"; shift ;;
    --out-dir=*) OUT_DIR="${1#*=}"; shift ;;
    --stage-only) STAGE_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --allow-stub|--allow-stub-sdk) ALLOW_STUB=1; shift ;;
    *) [ -z "$OFFER_FILE" ] && OFFER_FILE="$1"; shift ;;
  esac
done

[ -n "$OFFER_FILE" ] && [ -f "$OFFER_FILE" ] || { printf '[ERROR] Existing <offer.json> required.\n' >&2; exit 1; }

OFFER_ID=$(jq -r '.offer_id' "$OFFER_FILE")
OFFER_VER=$(jq -r '.version' "$OFFER_FILE")
[ -n "$OUT_DIR" ] || OUT_DIR="${LIBSCRIPT_ROOT_DIR}/build/infrastructure/marketplace/${OFFER_ID}"
mkdir -p "${OUT_DIR}/images"

# Compute offer content digest for 2x-rerun idempotency
if command -v sha256sum >/dev/null 2>&1; then
  OFFER_SHA=$(sha256sum "$OFFER_FILE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  OFFER_SHA=$(shasum -a 256 "$OFFER_FILE" | awk '{print $1}')
elif command -v sha256 >/dev/null 2>&1; then
  OFFER_SHA=$(sha256 -q "$OFFER_FILE" 2>/dev/null || sha256 "$OFFER_FILE" | awk '{print $NF}')
else
  OFFER_SHA=$(cksum "$OFFER_FILE" | awk '{print $1}')
fi

STAMP="${OUT_DIR}/.publish_stamp"
STAMP_KEY="${OFFER_SHA}:${CLOUDS_CSV}:${STAGE_ONLY}:${DRY_RUN}"
if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$STAMP_KEY" ]; then
  printf '[SKIP] Marketplace offer %s (%s) already synthesized at %s\n' "$OFFER_ID" "$OFFER_VER" "$OUT_DIR"
  exit 0
fi

# 1. Stage each appliance role sysroot and synthesize UEFI/GPT unikernel image
STUB_ARG=''
[ "$ALLOW_STUB" = "1" ] && STUB_ARG='--allow-stub-sdk'
jq -c '.appliance_images[]' "$OFFER_FILE" | while IFS= read -r _item; do
  _role=$(printf '%s' "$_item" | jq -r '.role')
  _prof=$(printf '%s' "$_item" | jq -r '.os_profile')
  _cloud_boot=$(printf '%s' "$_item" | jq -r '.cloud_boot // "uefi-gpt"')
  _prof_path="$_prof"
  [ -f "$_prof_path" ] || _prof_path="${LIBSCRIPT_ROOT_DIR}/${_prof}"
  _os_fam=$(jq -r '.target.os_family // "unikernel-unikraft"' "$_prof_path")
  _fw="${_os_fam#unikernel-}"
  _role_sys="${OUT_DIR}/images/${_role}/sysroot"
  _role_elf="${OUT_DIR}/images/${_role}/${_role}.raw"
  mkdir -p "$_role_sys"
  # shellcheck disable=SC2086
  STACK='' LIBSCRIPT_ALLOW_STUB="$ALLOW_STUB" \
    sh "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/unikernel_img.sh" \
    --framework="$_fw" --vmm=qemu --cloud-boot="$_cloud_boot" $STUB_ARG "$_role_sys" "$_role_elf" >/dev/null

  # Align 1 MiB copy for Azure VHD when Azure is targeted
  case ",${CLOUDS_CSV}," in
    *,azure,*)
      dd if=/dev/zero of="${OUT_DIR}/images/${_role}/${_role}.vhd" bs=1048576 count=1 2>/dev/null
      ;;
  esac
  case ",${CLOUDS_CSV}," in
    *,gcp,*)
      (cd "${OUT_DIR}/images/${_role}" && cp -f "${_role}.raw" disk.raw && tar -czf "${_role}.disk.raw.tar.gz" disk.raw && rm -f disk.raw)
      ;;
  esac
done

# 2. Run Pre-Marketplace Compliance & SPDX SBOM Gate across staged sysroots
STACK='' sh "${SCRIPT_DIR}/verify_compliance.sh" "$OFFER_FILE" \
  --sysroot-dir="${OUT_DIR}/images" --out-sbom="${OUT_DIR}/sbom.spdx.json"

# 3. Register cloud images & synthesize per-cloud Marketplace bundles
MODE_FLAGS=''
[ "$STAGE_ONLY" -eq 1 ] && MODE_FLAGS="${MODE_FLAGS} --stage-only"
[ "$DRY_RUN" -eq 1 ] && MODE_FLAGS="${MODE_FLAGS} --dry-run"
IMG_DRY=''
{ [ "$STAGE_ONLY" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; } && IMG_DRY='--dry-run'

_oifs="$IFS"; IFS=','
# shellcheck disable=SC2086
set -- $CLOUDS_CSV
IFS="$_oifs"
for _cloud in "$@"; do
  case "$_cloud" in
    aws)
      _bkt=$(jq -r '.targets.aws_marketplace.s3_staging_bucket // "libscript-mkt"' "$OFFER_FILE")
      _reg=$(jq -r '.targets.aws_marketplace.region // "us-east-1"' "$OFFER_FILE")
      jq -r '.appliance_images[].role' "$OFFER_FILE" | while IFS= read -r _r; do
        # shellcheck disable=SC2086
        STACK='' sh "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/image-import/aws_import.sh" \
          --disk="${OUT_DIR}/images/${_r}/${_r}.raw" --bucket="$_bkt" --region="$_reg" \
          --name="${OFFER_ID}-${_r}" --out="${OUT_DIR}/images/${_r}/aws-ami.json" $IMG_DRY >/dev/null
      done
      # shellcheck disable=SC2086
      STACK='' sh "${SCRIPT_DIR}/aws.sh" "$OFFER_FILE" --out-dir="${OUT_DIR}/aws" $MODE_FLAGS
      ;;
    azure)
      _acct=$(jq -r '.targets.azure_marketplace.storage_account // "libscript_mkt"' "$OFFER_FILE")
      _gal=$(jq -r '.targets.azure_marketplace.compute_gallery // "libscript_sig"' "$OFFER_FILE")
      _rg=$(jq -r '.targets.azure_marketplace.resource_group // "libscript-rg"' "$OFFER_FILE")
      jq -r '.appliance_images[].role' "$OFFER_FILE" | while IFS= read -r _r; do
        # shellcheck disable=SC2086
        STACK='' sh "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/image-import/azure_import.sh" \
          --disk="${OUT_DIR}/images/${_r}/${_r}.vhd" --account="$_acct" --gallery="$_gal" --rg="$_rg" \
          --name="${OFFER_ID}-${_r}" --version="$OFFER_VER" --out="${OUT_DIR}/images/${_r}/azure-sig.json" $IMG_DRY >/dev/null
      done
      # shellcheck disable=SC2086
      STACK='' sh "${SCRIPT_DIR}/azure.sh" "$OFFER_FILE" --out-dir="${OUT_DIR}/azure" $MODE_FLAGS
      ;;
    gcp)
      _gcp_bkt=$(jq -r '.targets.gcp_marketplace.gcs_staging_bucket // "libscript-gcp-mkt"' "$OFFER_FILE")
      _gcp_proj=$(jq -r '.targets.gcp_marketplace.project_id // "libscript-mkt-proj"' "$OFFER_FILE")
      jq -r '.appliance_images[].role' "$OFFER_FILE" | while IFS= read -r _r; do
        # shellcheck disable=SC2086
        STACK='' sh "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/image-import/gcp_import.sh" \
          --disk="${OUT_DIR}/images/${_r}/${_r}.disk.raw.tar.gz" --bucket="$_gcp_bkt" --project="$_gcp_proj" \
          --name="${OFFER_ID}-${_r}" --out="${OUT_DIR}/images/${_r}/gcp-image.json" $IMG_DRY >/dev/null
      done
      # shellcheck disable=SC2086
      STACK='' sh "${SCRIPT_DIR}/gcp.sh" "$OFFER_FILE" --out-dir="${OUT_DIR}/gcp" $MODE_FLAGS
      ;;
    *)
      printf '[ERROR] Unsupported marketplace target cloud: %s\n' "$_cloud" >&2
      exit 1
      ;;
  esac
done
IFS="$_oifs"

printf '%s\n' "$STAMP_KEY" > "${STAMP}.tmp"
mv "${STAMP}.tmp" "$STAMP"
printf '[OK] Multicloud marketplace offer %s (%s) published/staged at %s\n' "$OFFER_ID" "$CLOUDS_CSV" "$OUT_DIR"
