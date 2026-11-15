#!/bin/sh
# ## Overview
# Uploads a raw/UEFI disk image to S3 (digest-guarded) and registers an AWS EC2 AMI with ENA and UEFI boot mode.
#
# ## Usage
# ./_lib/cloud/image-import/aws_import.sh --disk=<path> --bucket=<s3_bucket> --name=<ami_name> [--region=<reg>] [--out=<receipt.json>] [--dry-run]

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
AMI_NAME=''
REGION='us-east-1'
ARCH_VAL="${IMAGE_IMPORT_ARCH:-x86_64}"
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --bucket=*) BUCKET="${1#*=}"; shift ;;
    --name=*) AMI_NAME="${1#*=}"; shift ;;
    --region=*) REGION="${1#*=}"; shift ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --dry-run) DRY_RUN='1'; shift ;;
    *) shift ;;
  esac
done

[ -n "$DISK_PATH" ] && [ -f "$DISK_PATH" ] || { printf '[ERROR] --disk=<existing_file> required\n' >&2; exit 1; }
[ -n "$BUCKET" ] || { printf '[ERROR] --bucket=<s3_bucket> required\n' >&2; exit 1; }
[ -n "$AMI_NAME" ] || { printf '[ERROR] --name=<ami_name> required\n' >&2; exit 1; }

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
S3_KEY="libscript-images/${AMI_NAME}-${SHORT_SHA}.raw"
[ -n "$OUT_RECEIPT" ] || OUT_RECEIPT="${DISK_PATH}.aws-ami-receipt.json"

if [ -f "$OUT_RECEIPT" ] && jq -e --arg d "$DIGEST" '.sha256 == $d' "$OUT_RECEIPT" >/dev/null 2>&1; then
  printf '[SKIP] AWS AMI already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_RECEIPT"
  exit 0
fi

AMI_ID="ami-dryrun-${SHORT_SHA}"
if [ "$DRY_RUN" != "1" ]; then
  _existing=$(aws ec2 describe-images --owners self --region "$REGION" \
    --filters "Name=tag:LibScriptDigest,Values=${DIGEST}" --query 'Images[0].ImageId' --output text 2>/dev/null || true)
  if [ -n "$_existing" ] && [ "$_existing" != "None" ]; then
    AMI_ID="$_existing"
  else
    aws s3 cp "$DISK_PATH" "s3://${BUCKET}/${S3_KEY}" --region "$REGION"
    _task_id=$(aws ec2 import-snapshot --region "$REGION" \
      --disk-container "Description=${AMI_NAME},Format=RAW,UserBucket={S3Bucket=${BUCKET},S3Key=${S3_KEY}}" \
      --query 'ImportTaskId' --output text)
    while :; do
      _st=$(aws ec2 describe-import-snapshot-tasks --region "$REGION" --import-task-ids "$_task_id" \
        --query 'ImportSnapshotTasks[0].SnapshotTaskDetail.Status' --output text)
      [ "$_st" = 'completed' ] && break
      [ "$_st" = 'deleted' ] || [ "$_st" = 'deleting' ] && { printf '[ERROR] AWS snapshot import failed\n' >&2; exit 1; }
      sleep 10
    done
    _snap_id=$(aws ec2 describe-import-snapshot-tasks --region "$REGION" --import-task-ids "$_task_id" \
      --query 'ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId' --output text)
    AMI_ID=$(aws ec2 register-image --region "$REGION" \
      --name "${AMI_NAME}-${SHORT_SHA}" \
      --architecture "$ARCH_VAL" \
      --virtualization-type hvm \
      --boot-mode uefi \
      --ena-support \
      --root-device-name /dev/xvda \
      --block-device-mappings "DeviceName=/dev/xvda,Ebs={SnapshotId=${_snap_id},VolumeType=gp3,DeleteOnTermination=true}" \
      --tag-specifications "ResourceType=image,Tags=[{Key=LibScriptDigest,Value=${DIGEST}}]" \
      --query 'ImageId' --output text)
  fi
fi

mkdir -p "$(dirname -- "$OUT_RECEIPT")"
cat << EOF > "${OUT_RECEIPT}.tmp"
{
  "cloud": "aws",
  "ami_id": "${AMI_ID}",
  "name": "${AMI_NAME}",
  "region": "${REGION}",
  "architecture": "${ARCH_VAL}",
  "boot_mode": "uefi",
  "ena_support": true,
  "s3_uri": "s3://${BUCKET}/${S3_KEY}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] AWS AMI registration receipt written: %s (%s)\n' "$OUT_RECEIPT" "$AMI_ID"
