#!/bin/sh
# ## Overview
# Uploads a disk artifact (including `package-as {linux,freebsd,illumos,reactos,unikernel}-distro`
# outputs) to S3 (digest-guarded) and registers an AWS EC2 AMI with ENA and UEFI/BIOS boot mode.
#
# ## Usage
# ./infrastructure/resources/image-import/aws_import.sh --disk=<path> --bucket=<s3_bucket> [--name=<ami_name>] [--distro=<target>] [--profile=<preset>] [--region=<reg>] [--arch=<x86_64|arm64>] [--out=<receipt.json>] [--dry-run]

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
BUCKET="${IMAGE_IMPORT_AWS_BUCKET:-}"
AMI_NAME=''
DISTRO_TARGET=''
PROFILE_ARG=''
REGION="${IMAGE_IMPORT_AWS_REGION:-us-east-1}"
ARCH_VAL=''
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## show_help
# Displays CLI usage instructions for aws_import.sh.
show_help() {
  printf '%s\n' 'Usage: aws_import.sh [--disk=<path> | --distro=<target> --profile=<preset>] --bucket=<s3_bucket> [--name=<ami_name>] [--region=<reg>] [--arch=<x86_64|arm64>] [--out=<receipt.json>] [--dry-run]'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --disk) DISK_PATH="${2:-}"; shift 2 ;;
    --bucket=*) BUCKET="${1#*=}"; shift ;;
    --bucket) BUCKET="${2:-}"; shift 2 ;;
    --name=*) AMI_NAME="${1#*=}"; shift ;;
    --name) AMI_NAME="${2:-}"; shift 2 ;;
    --distro=*|--target=*) DISTRO_TARGET="${1#*=}"; shift ;;
    --distro|--target) DISTRO_TARGET="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_ARG="${1#*=}"; shift ;;
    --profile) PROFILE_ARG="${2:-}"; shift 2 ;;
    --region=*) REGION="${1#*=}"; shift ;;
    --region) REGION="${2:-}"; shift 2 ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --arch) ARCH_VAL="${2:-}"; shift 2 ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --out) OUT_RECEIPT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --allow-stub) ALLOW_STUB='1'; shift ;;
    *) shift ;;
  esac
done

# ## synthesize_distro_if_needed
# Synthesizes a raw/UEFI disk artifact via package-as when --distro is given without --disk.
synthesize_distro_if_needed() {
  [ -z "$DISK_PATH" ] && [ -n "$DISTRO_TARGET" ] || return 0
  case "$DISTRO_TARGET" in
    linux-distro|freebsd-distro|illumos-distro|reactos-distro|unikernel-distro) ;;
    *)
      printf '[ERROR] Unsupported --distro target for AWS import: %s\n' "$DISTRO_TARGET" >&2
      exit 1
      ;;
  esac
  _aws_fmt='raw'
  [ "$DISTRO_TARGET" = 'unikernel-distro' ] && _aws_fmt='uefi-gpt'
  _aws_tmp="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/image-import/aws-${DISTRO_TARGET}.raw"
  mkdir -p "$(dirname "$_aws_tmp")"
  set -- package-as "$DISTRO_TARGET" --format "$_aws_fmt" --output "$_aws_tmp"
  [ -n "$PROFILE_ARG" ] && set -- "$@" --profile "$PROFILE_ARG"
  [ "$ALLOW_STUB" = '1' ] && set -- "$@" --allow-stub
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" "$@"
  DISK_PATH="$_aws_tmp"
}

# ## detect_distro_metadata
# Infers distro_family, architecture, boot_mode, snapshot_format, and default AMI name from artifact and companion stamps.
detect_distro_metadata() {
  DISTRO_FAMILY='generic'
  BOOT_MODE='uefi'
  SNAP_FMT='RAW'
  _base=$(basename "$DISK_PATH")
  _stem="${_base%.*}"

  case "$_base" in
    linux-*|*linux*) DISTRO_FAMILY='linux' ;;
    freebsd-*|*freebsd*) DISTRO_FAMILY='freebsd' ;;
    illumos-*|*illumos*) DISTRO_FAMILY='illumos' ;;
    reactos-*|*reactos*) DISTRO_FAMILY='reactos' ;;
    unikernel-*|*.unikernel.*|*.uefi-gpt.*) DISTRO_FAMILY='unikernel' ;;
  esac
  if [ -n "$DISTRO_TARGET" ]; then
    DISTRO_FAMILY="${DISTRO_TARGET%-distro}"
  fi

  for _st in "${DISK_PATH}.distro.stamp" "${DISK_PATH}.stamp"; do
    if [ -f "$_st" ]; then
      _prof_line=$(grep '^profile=' "$_st" 2>/dev/null | head -n 1 || true)
      _arch_line=$(grep '^arch=' "$_st" 2>/dev/null | head -n 1 || true)
      _fw_line=$(grep '^framework=' "$_st" 2>/dev/null | head -n 1 || true)
      case "$_prof_line" in
        *freebsd*) DISTRO_FAMILY='freebsd' ;;
        *illumos*) DISTRO_FAMILY='illumos' ;;
        *reactos*) DISTRO_FAMILY='reactos' ;;
        *unikernel*) DISTRO_FAMILY='unikernel' ;;
        *linux*|*lfs*) DISTRO_FAMILY='linux' ;;
      esac
      [ -n "$_fw_line" ] && DISTRO_FAMILY='unikernel'
      if [ -z "$ARCH_VAL" ] && [ -n "$_arch_line" ]; then
        ARCH_VAL="${_arch_line#arch=}"
      fi
      case "$_prof_line" in
        *i686*|*i386*)
          [ -z "$ARCH_VAL" ] && ARCH_VAL='i386'
          BOOT_MODE='legacy-bios'
          ;;
        *aarch64*|*arm64*)
          [ -z "$ARCH_VAL" ] && ARCH_VAL='arm64'
          ;;
      esac
    fi
  done

  case "$_base" in
    *i686*|*i386*)
      [ -z "$ARCH_VAL" ] && ARCH_VAL='i386'
      BOOT_MODE='legacy-bios'
      ;;
    *aarch64*|*arm64*)
      [ -z "$ARCH_VAL" ] && ARCH_VAL='arm64'
      ;;
  esac

  [ -n "$ARCH_VAL" ] || ARCH_VAL="${IMAGE_IMPORT_ARCH:-x86_64}"
  case "$ARCH_VAL" in
    aarch64|ARM64) ARCH_VAL='arm64' ;;
    x86_64|X86_64|amd64) ARCH_VAL='x86_64' ;;
    i686|i386) ARCH_VAL='i386'; BOOT_MODE='legacy-bios' ;;
  esac

  UPLOAD_DISK="$DISK_PATH"
  case "$_base" in
    *.vhd|*.VHD) SNAP_FMT='VHD' ;;
    *.vmdk|*.VMDK) SNAP_FMT='VMDK' ;;
    *.qcow2)
      if [ "$DRY_RUN" != '1' ] && command -v qemu-img >/dev/null 2>&1; then
        UPLOAD_DISK="${DISK_PATH}.aws.raw"
        if [ ! -f "$UPLOAD_DISK" ]; then
          qemu-img convert -f qcow2 -O raw "$DISK_PATH" "$UPLOAD_DISK"
        fi
      fi
      SNAP_FMT='RAW'
      ;;
    *) SNAP_FMT='RAW' ;;
  esac

  if [ -z "$AMI_NAME" ]; then
    AMI_NAME=$(printf '%s' "$_stem" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//;s/-$//')
  fi
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

synthesize_distro_if_needed

[ -n "$DISK_PATH" ] && [ -f "$DISK_PATH" ] || { printf '[ERROR] --disk=<existing_file> required\n' >&2; exit 1; }
[ -n "$BUCKET" ] || { printf '[ERROR] --bucket=<s3_bucket> required\n' >&2; exit 1; }

detect_distro_metadata
[ -n "$AMI_NAME" ] || { printf '[ERROR] --name=<ami_name> required\n' >&2; exit 1; }

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
S3_EXT='raw'
[ "$SNAP_FMT" = 'VHD' ] && S3_EXT='vhd'
[ "$SNAP_FMT" = 'VMDK' ] && S3_EXT='vmdk'
S3_KEY="libscript-images/${AMI_NAME}-${SHORT_SHA}.${S3_EXT}"
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
    aws s3 cp "$UPLOAD_DISK" "s3://${BUCKET}/${S3_KEY}" --region "$REGION"
    _task_id=$(aws ec2 import-snapshot --region "$REGION" \
      --disk-container "Description=${AMI_NAME},Format=${SNAP_FMT},UserBucket={S3Bucket=${BUCKET},S3Key=${S3_KEY}}" \
      --query 'ImportTaskId' --output text)
    aws ec2 wait snapshot-imported --region "$REGION" --import-task-ids "$_task_id"
    _snap_id=$(aws ec2 describe-import-snapshot-tasks --region "$REGION" --import-task-ids "$_task_id" \
      --query 'ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId' --output text)
    AMI_ID=$(aws ec2 register-image --region "$REGION" \
      --name "${AMI_NAME}-${SHORT_SHA}" \
      --architecture "$ARCH_VAL" \
      --boot-mode "$BOOT_MODE" \
      --ena-support \
      --root-device-name /dev/xvda \
      --block-device-mappings "DeviceName=/dev/xvda,Ebs={SnapshotId=${_snap_id},VolumeType=gp3,DeleteOnTermination=true}" \
      --tag-specifications "ResourceType=image,Tags=[{Key=LibScriptDigest,Value=${DIGEST}},{Key=LibScriptDistro,Value=${DISTRO_FAMILY}}]" \
      --query 'ImageId' --output text)
  fi
fi

mkdir -p "$(dirname "$OUT_RECEIPT")"
cat > "${OUT_RECEIPT}.tmp" <<EOF
{
  "cloud": "aws",
  "distro_family": "${DISTRO_FAMILY}",
  "source_artifact": "${DISK_PATH}",
  "snapshot_format": "${SNAP_FMT}",
  "region": "${REGION}",
  "ami_id": "${AMI_ID}",
  "name": "${AMI_NAME}-${SHORT_SHA}",
  "architecture": "${ARCH_VAL}",
  "boot_mode": "${BOOT_MODE}",
  "ena_support": true,
  "s3_uri": "s3://${BUCKET}/${S3_KEY}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] AWS AMI registration receipt written: %s (%s)\n' "$OUT_RECEIPT" "$AMI_ID"
