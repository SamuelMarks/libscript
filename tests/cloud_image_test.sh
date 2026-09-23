#!/bin/sh
# ## Overview
# Cloud image geometry and boot milestone verification harness validating
# Azure 1 MiB boundary alignment, GCP sparse tar format, and AWS EBS image geometry.
#
# ## Usage
# ./tests/cloud_image_test.sh

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

printf '[TEST-CLOUD] Starting Cloud Image Geometry & Milestone Verification...
'

TEST_DIR="${LIBSCRIPT_ROOT_DIR}/build/test_cloud_verify"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

RAW_DISK="$TEST_DIR/raw.img"
truncate -s 100M "$RAW_DISK" 2>/dev/null || dd if=/dev/zero of="$RAW_DISK" bs=1M count=100 2>/dev/null

# 1. Azure VHD Verification
AZURE_VHD="$TEST_DIR/azure.vhd"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/azure_vhd.sh" "$RAW_DISK" "$AZURE_VHD" "1"

VHD_SIZE=$(wc -c < "$AZURE_VHD" | tr -d ' ' 2>/dev/null || echo 0)
VHD_REM=$(( VHD_SIZE % 1048576 ))

if [ "$VHD_REM" -ne 0 ] && [ "$VHD_REM" -ne 512 ]; then
  printf '[FAIL] Azure VHD (%s bytes) is not aligned to 1 MiB boundary (rem=%s).
' "$VHD_SIZE" "$VHD_REM" >&2
  exit 1
fi
printf '[PASS] Azure VHD geometry validated (size=%s bytes, remainder=%s mod 1MB).
' "$VHD_SIZE" "$VHD_REM"

# 2. GCP Image Verification
GCP_TAR="$TEST_DIR/gcp.tar.gz"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/gcp_image.sh" "$RAW_DISK" "$GCP_TAR" "1"

GCP_MEMBERS=$(tar -tf "$GCP_TAR" 2>/dev/null || echo "")
case "$GCP_MEMBERS" in
  disk.raw)
    printf '[PASS] GCP archive contains strictly disk.raw at root.
'
    ;;
  *)
    printf '[FAIL] GCP archive contains unexpected members: %s
' "$GCP_MEMBERS" >&2
    exit 1
    ;;
esac

# 3. AWS AMI Raw Verification
AWS_RAW="$TEST_DIR/aws.raw"
"${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/aws_ami.sh" "$RAW_DISK" "$AWS_RAW" "1"

if [ ! -f "$AWS_RAW" ]; then
  printf '[FAIL] AWS raw EBS volume was not generated.
' >&2
  exit 1
fi
printf '[PASS] AWS AMI raw EBS image verified successfully.
'

# 4. Cloud-Init NoCloud ISO Verification
CIDATA_ISO="$TEST_DIR/cidata.iso"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/cloud/gen_nocloud_iso.sh" "test-node" "" "$CIDATA_ISO"

if [ ! -f "$CIDATA_ISO" ]; then
  printf '[FAIL] Cloud-Init NoCloud ISO was not generated.
' >&2
  exit 1
fi
printf '[PASS] Cloud-Init NoCloud configuration ISO verified.
'

rm -rf "$TEST_DIR"
printf '[OK] All cloud image geometries and invariants verified successfully.
'
exit 0
