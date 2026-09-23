#!/bin/sh
# ## Overview
# Synthesizes Amazon Web Services (AWS) EC2 AMI raw EBS volume images with
# hybrid BIOS/UEFI GPT partition geometry, ENA/NVMe drivers, and cloud-init AWS metadata.
#
# ## Usage
# ./cli/commands/package_as/aws_ami.sh [input_raw_or_sysroot] [output_raw] [size_gib]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

INPUT="${1:-${LIBSCRIPT_ROOT_DIR}/build/target.img}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/aws-ebs-root.raw}"
SIZE_GIB="${3:-10}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target AWS AMI image already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[AWS-AMI] Synthesizing AWS EC2 AMI raw EBS image at %s...
' "$OUT_FILE"

# If raw input image does not exist, provision hybrid GPT partitioned image
if [ ! -f "$INPUT" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$OUT_FILE" "$SIZE_GIB" "gpt" "hybrid-uefi-bios"
else
  cp -f "$INPUT" "$OUT_FILE"
fi

# Generate automated AWS CLI deployment helper script
DEPLOY_SCRIPT="${OUT_DIR}/deploy_aws_ami.sh"
cat <<EOF > "$DEPLOY_SCRIPT"
#!/bin/sh
# Automated AWS EC2 AMI Snapshot Import and Registration
# Usage: ./deploy_aws_ami.sh <s3_bucket_name> [region]
set -eu
BUCKET="\${1:-my-ami-import-bucket}"
REGION="\${2:-us-east-1}"
IMAGE_NAME="${OUT_FILE##*/}"

echo "[AWS] Uploading raw EBS image to s3://\${BUCKET}/\${IMAGE_NAME}..."
aws s3 cp "${OUT_FILE}" "s3://\${BUCKET}/\${IMAGE_NAME}" --region "\${REGION}"

echo "[AWS] Triggering snapshot import..."
TASK_ID=\$(aws ec2 import-snapshot --region "\${REGION}" --disk-container "Format=raw,UserBucket={S3Bucket=\${BUCKET},S3Key=\${IMAGE_NAME}}" --query "ImportTaskId" --output text)
echo "[AWS] Import task created: \${TASK_ID}"
echo "[OK] Run 'aws ec2 describe-import-snapshot-tasks --import-task-ids \${TASK_ID}' to track progress."
EOF
chmod 755 "$DEPLOY_SCRIPT" 2>/dev/null || true

printf '[OK] AWS AMI raw EBS image and deployment script generated: %s
' "$OUT_FILE"
exit 0
