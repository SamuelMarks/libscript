#!/bin/sh
# ## Overview
# Unified public cloud image packaging driver, dispatching to AWS AMI,
# Microsoft Azure VHD, and Google Cloud Platform disk.raw.tar.gz builders.
#
# ## Usage
# ./cli/commands/package_as/cloud_img.sh [--provider=aws|azure|gcp|all] [input_raw] [out_dir]

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

PROVIDER="all"
INPUT="${LIBSCRIPT_ROOT_DIR}/build/target.img"
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/build/cloud_images"

while [ $# -gt 0 ]; do
  case "$1" in
    --provider=*) PROVIDER="${1#*=}"; shift ;;
    aws|azure|gcp|all) PROVIDER="$1"; shift ;;
    *)
      if [ -f "$1" ]; then
        INPUT="$1"
      elif [ -d "$1" ] || [ ! -e "$1" ]; then
        OUT_DIR="$1"
      fi
      shift
      ;;
  esac
done

mkdir -p "$OUT_DIR"

printf '[CLOUD-IMG] Packaging cloud images for provider: %s...
' "$PROVIDER"

if [ "$PROVIDER" = "all" ] || [ "$PROVIDER" = "aws" ]; then
  "${SCRIPT_DIR}/aws_ami.sh" "$INPUT" "${OUT_DIR}/aws-ebs-root.raw"
fi

if [ "$PROVIDER" = "all" ] || [ "$PROVIDER" = "azure" ]; then
  "${SCRIPT_DIR}/azure_vhd.sh" "$INPUT" "${OUT_DIR}/disk.vhd"
fi

if [ "$PROVIDER" = "all" ] || [ "$PROVIDER" = "gcp" ]; then
  "${SCRIPT_DIR}/gcp_image.sh" "$INPUT" "${OUT_DIR}/gcp-disk.raw.tar.gz"
fi

printf '[OK] Cloud packaging completed under: %s
' "$OUT_DIR"
exit 0
