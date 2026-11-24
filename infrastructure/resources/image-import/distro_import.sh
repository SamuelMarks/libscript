#!/bin/sh
# ## Overview
# Unified multicloud distro image importer for `package-as {linux,freebsd,illumos,reactos,unikernel}-distro` across AWS, GCP, and Azure.
# ## Usage
# ./infrastructure/resources/image-import/distro_import.sh [--disk=<artifact> | --distro=<target> --profile=<preset>] [--clouds=aws,gcp,azure] [--name=<img_name>] [--out=<manifest.json>] [--dry-run] [--allow-stub]
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
DISTRO_TARGET=''
PROFILE_ARG=''
FORMAT_ARG=''
CLOUDS_CSV='aws,gcp,azure'
IMG_NAME=''
AWS_BUCKET="${IMAGE_IMPORT_AWS_BUCKET:-libscript-ami-staging}"
AWS_REGION="${IMAGE_IMPORT_AWS_REGION:-us-east-1}"
GCP_BUCKET="${IMAGE_IMPORT_GCP_BUCKET:-libscript-gce-staging}"
GCP_PROJECT="${IMAGE_IMPORT_GCP_PROJECT:-libscript-cloud}"
AZURE_ACCOUNT="${IMAGE_IMPORT_AZURE_ACCOUNT:-libscriptvhd}"
AZURE_RG="${IMAGE_IMPORT_AZURE_RG:-libscript-marketplace-rg}"
AZURE_GALLERY="${IMAGE_IMPORT_AZURE_GALLERY:-}"
ARCH_VAL=''
OUT_MANIFEST=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## show_help
# Displays CLI usage instructions for distro_import.sh.
show_help() {
  printf '%s\n' 'Usage: distro_import.sh [--disk=<artifact> | --distro=<linux-distro|freebsd-distro|illumos-distro|reactos-distro|unikernel-distro> --profile=<preset>] [--clouds=aws,gcp,azure] [--name=<img_name>] [--aws-bucket=<bkt>] [--gcp-bucket=<bkt>] [--gcp-project=<proj>] [--azure-account=<acct>] [--azure-rg=<rg>] [--azure-gallery=<sig>] [--out=<manifest.json>] [--dry-run] [--allow-stub]'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --disk) DISK_PATH="${2:-}"; shift 2 ;;
    --distro=*|--target=*) DISTRO_TARGET="${1#*=}"; shift ;;
    --distro|--target) DISTRO_TARGET="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_ARG="${1#*=}"; shift ;;
    --profile) PROFILE_ARG="${2:-}"; shift 2 ;;
    --format=*) FORMAT_ARG="${1#*=}"; shift ;;
    --format) FORMAT_ARG="${2:-}"; shift 2 ;;
    --clouds=*) CLOUDS_CSV="${1#*=}"; shift ;;
    --clouds) CLOUDS_CSV="${2:-}"; shift 2 ;;
    --name=*) IMG_NAME="${1#*=}"; shift ;;
    --name) IMG_NAME="${2:-}"; shift 2 ;;
    --aws-bucket=*) AWS_BUCKET="${1#*=}"; shift ;;
    --aws-bucket) AWS_BUCKET="${2:-}"; shift 2 ;;
    --aws-region=*|--region=*) AWS_REGION="${1#*=}"; shift ;;
    --aws-region|--region) AWS_REGION="${2:-}"; shift 2 ;;
    --gcp-bucket=*) GCP_BUCKET="${1#*=}"; shift ;;
    --gcp-bucket) GCP_BUCKET="${2:-}"; shift 2 ;;
    --gcp-project=*|--project=*) GCP_PROJECT="${1#*=}"; shift ;;
    --gcp-project|--project) GCP_PROJECT="${2:-}"; shift 2 ;;
    --azure-account=*|--account=*) AZURE_ACCOUNT="${1#*=}"; shift ;;
    --azure-account|--account) AZURE_ACCOUNT="${2:-}"; shift 2 ;;
    --azure-rg=*|--rg=*) AZURE_RG="${1#*=}"; shift ;;
    --azure-rg|--rg) AZURE_RG="${2:-}"; shift 2 ;;
    --azure-gallery=*|--gallery=*) AZURE_GALLERY="${1#*=}"; shift ;;
    --azure-gallery|--gallery) AZURE_GALLERY="${2:-}"; shift 2 ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --arch) ARCH_VAL="${2:-}"; shift 2 ;;
    --out=*) OUT_MANIFEST="${1#*=}"; shift ;;
    --out) OUT_MANIFEST="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --allow-stub) ALLOW_STUB='1'; shift ;;
    *) shift ;;
  esac
done

# ## ensure_source_artifact
# Synthesizes a canonical package-as distro artifact when --distro is supplied without --disk.
ensure_source_artifact() {
  if [ -n "$DISK_PATH" ]; then
    if [ ! -f "$DISK_PATH" ]; then
      printf '[ERROR] Artifact not found: %s\n' "$DISK_PATH" >&2
      exit 1
    fi
    return 0
  fi
  if [ -z "$DISTRO_TARGET" ]; then
    printf '[ERROR] Either --disk=<artifact> or --distro=<target> is required.\n' >&2
    exit 1
  fi
  case "$DISTRO_TARGET" in
    linux-distro|freebsd-distro|illumos-distro|reactos-distro|unikernel-distro) ;;
    *)
      printf '[ERROR] Unsupported distro target: %s (expected {linux,freebsd,illumos,reactos,unikernel}-distro)\n' "$DISTRO_TARGET" >&2
      exit 1
      ;;
  esac
  _fmt="${FORMAT_ARG:-raw}"
  if [ -z "$FORMAT_ARG" ] && [ "$DISTRO_TARGET" = 'unikernel-distro' ]; then
    _fmt='uefi-gpt'
  fi
  _out_base="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/image-import/${DISTRO_TARGET}"
  if [ -n "$PROFILE_ARG" ]; then
    _out_base="${_out_base}-$(basename "${PROFILE_ARG%.json}")"
  fi
  DISK_PATH="${_out_base}.${_fmt}"
  mkdir -p "$(dirname "$DISK_PATH")"
  set -- package-as "$DISTRO_TARGET" --format "$_fmt" --output "$DISK_PATH"
  if [ -n "$PROFILE_ARG" ]; then set -- "$@" --profile "$PROFILE_ARG"; fi
  if [ "$ALLOW_STUB" = '1' ]; then set -- "$@" --allow-stub; fi
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" "$@"
}

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

ensure_source_artifact

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
if [ -z "$OUT_MANIFEST" ]; then OUT_MANIFEST="${DISK_PATH}.multicloud-receipt.json"; fi

if [ -f "$OUT_MANIFEST" ] && jq -e --arg d "$DIGEST" --arg c "$CLOUDS_CSV" '.sha256 == $d and .clouds_requested == $c' "$OUT_MANIFEST" >/dev/null 2>&1; then
  printf '[SKIP] Multicloud distro image import already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_MANIFEST"
  exit 0
fi

AWS_REC=''
GCP_REC=''
AZ_REC=''

_old_ifs="$IFS"
IFS=','
# shellcheck disable=SC2086
set -- $CLOUDS_CSV
IFS="$_old_ifs"

for _cloud in "$@"; do
  case "$_cloud" in
    aws)
      AWS_REC="${DISK_PATH}.aws-ami-receipt.json"
      set -- --disk="$DISK_PATH" --bucket="$AWS_BUCKET" --region="$AWS_REGION" --out="$AWS_REC"
      if [ -n "$IMG_NAME" ]; then set -- "$@" --name="$IMG_NAME"; fi
      if [ -n "$DISTRO_TARGET" ]; then set -- "$@" --distro="$DISTRO_TARGET"; fi
      if [ -n "$ARCH_VAL" ]; then set -- "$@" --arch="$ARCH_VAL"; fi
      if [ "$DRY_RUN" = '1' ]; then set -- "$@" --dry-run; fi
      STACK='' "${SCRIPT_DIR}/aws_import.sh" "$@"
      ;;
    gcp)
      GCP_REC="${DISK_PATH}.gcp-image-receipt.json"
      set -- --disk="$DISK_PATH" --bucket="$GCP_BUCKET" --project="$GCP_PROJECT" --out="$GCP_REC"
      if [ -n "$IMG_NAME" ]; then set -- "$@" --name="$IMG_NAME"; fi
      if [ -n "$DISTRO_TARGET" ]; then set -- "$@" --distro="$DISTRO_TARGET"; fi
      if [ -n "$ARCH_VAL" ]; then set -- "$@" --arch="$ARCH_VAL"; fi
      if [ "$DRY_RUN" = '1' ]; then set -- "$@" --dry-run; fi
      STACK='' "${SCRIPT_DIR}/gcp_import.sh" "$@"
      ;;
    azure)
      AZ_REC="${DISK_PATH}.azure-sig-receipt.json"
      set -- --disk="$DISK_PATH" --account="$AZURE_ACCOUNT" --rg="$AZURE_RG" --out="$AZ_REC"
      if [ -n "$AZURE_GALLERY" ]; then set -- "$@" --gallery="$AZURE_GALLERY"; fi
      if [ -n "$IMG_NAME" ]; then set -- "$@" --name="$IMG_NAME"; fi
      if [ -n "$DISTRO_TARGET" ]; then set -- "$@" --distro="$DISTRO_TARGET"; fi
      if [ -n "$ARCH_VAL" ]; then set -- "$@" --arch="$ARCH_VAL"; fi
      if [ "$DRY_RUN" = '1' ]; then set -- "$@" --dry-run; fi
      STACK='' "${SCRIPT_DIR}/azure_import.sh" "$@"
      ;;
    '') ;;
    *)
      printf '[ERROR] Unsupported cloud in --clouds: %s\n' "$_cloud" >&2
      exit 1
      ;;
  esac
done

AWS_JSON='null'
if [ -n "$AWS_REC" ] && [ -f "$AWS_REC" ]; then AWS_JSON=$(cat "$AWS_REC"); fi
GCP_JSON='null'
if [ -n "$GCP_REC" ] && [ -f "$GCP_REC" ]; then GCP_JSON=$(cat "$GCP_REC"); fi
AZ_JSON='null'
if [ -n "$AZ_REC" ] && [ -f "$AZ_REC" ]; then AZ_JSON=$(cat "$AZ_REC"); fi

mkdir -p "$(dirname "$OUT_MANIFEST")"
cat > "${OUT_MANIFEST}.tmp" <<EOF
{
  "source_artifact": "${DISK_PATH}",
  "distro_target": "${DISTRO_TARGET}",
  "clouds_requested": "${CLOUDS_CSV}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN},
  "registrations": {
    "aws": ${AWS_JSON},
    "gcp": ${GCP_JSON},
    "azure": ${AZ_JSON}
  }
}
EOF
mv "${OUT_MANIFEST}.tmp" "$OUT_MANIFEST"
printf '[OK] Multicloud distro image import manifest written: %s\n' "$OUT_MANIFEST"
