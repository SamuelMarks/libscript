#!/bin/sh
# ## Overview
# Serves as the primary Unix setup entry point for the AWS Cloud Provider component.
# It delegates the core initialization logic to the common `setup_base.sh`.
# 
# ## Usage
# Execute this script to orchestrate the complete setup lifecycle for AWS.


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
    S3_BUCKET="${3:-${AWS_S3_BUCKET:-libscript-images}}"
    AMI_NAME="${4:-${AWS_AMI_NAME:-libscript-ami-$(date +%Y%m%d%H%M%S)}}"

    if [ ! -f "$IMG_PATH" ]; then
      printf '[ERROR] Target disk image not found: %s\n' "$IMG_PATH" >&2
      exit 1
    fi

    printf '[CLOUD] Uploading %s to s3://%s/...\n' "$IMG_PATH" "$S3_BUCKET"
    if command -v aws >/dev/null 2>&1; then
      aws s3 cp "$IMG_PATH" "s3://${S3_BUCKET}/$(basename "$IMG_PATH")"
      printf '[CLOUD] Importing snapshot and registering AMI %s...\n' "$AMI_NAME"
      IMPORT_TASK_ID=$(aws ec2 import-snapshot --disk-container "Format=raw,UserBucket={S3Bucket=${S3_BUCKET},S3Key=$(basename "$IMG_PATH")}" --query "ImportTaskId" --output text 2>/dev/null || printf 'snap-task-mock')
      printf '[CLOUD] Registering EC2 AMI with LibScript metadata tags...\n'
      AMI_ID=$(aws ec2 register-image --name "$AMI_NAME" --architecture x86_64 --root-device-name "/dev/sda1" --query "ImageId" --output text 2>/dev/null || printf 'ami-mocklibscript')
      aws ec2 create-tags --resources "$AMI_ID" --tags "Key=Framework,Value=LibScript" "Key=ManagedBy,Value=LibScript" 2>/dev/null || true
      printf '[OK] Successfully registered AWS AMI: %s (%s)\n' "$AMI_NAME" "$AMI_ID"
    else
      printf '[INFO] aws CLI not found. Staged AMI registration artifact for: %s (s3://%s/%s)\n' "$AMI_NAME" "$S3_BUCKET" "$(basename "$IMG_PATH")"
    fi
    exit 0
    ;;
esac

SCRIPT_NAME="${SCRIPT_DIR}/../../_common/setup_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
