#!/bin/sh
# ## Overview
# Provisions cloud infrastructure and registers synthesized system images.
# Validates target profiles, builds missing image artifacts via Tier 2,
# and deploys resources across AWS, GCP, Azure, Proxmox, Hetzner, and Firecracker.
#
# ## Usage
# Run `provision.sh [--profile=<file>] [--image=<path>] [--provider=aws|gcp|azure|proxmox|hetzner|firecracker] [args...]`

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

PROFILE=""
IMAGE_PATH=""
PROVIDER=""

for arg in "$@"; do
  case "$arg" in
    --profile=*) PROFILE="${arg#--profile=}" ;;
    --image=*) IMAGE_PATH="${arg#--image=}" ;;
    --provider=*) PROVIDER="${arg#--provider=}" ;;
    aws|azure|gcp|proxmox|hetzner|firecracker) PROVIDER="$arg" ;;
  esac
done

if [ -n "$PROFILE" ] && [ -f "$PROFILE" ]; then
  printf '[PROVISION] Preparing deployment from profile: %s
' "$PROFILE"
  if [ -z "$IMAGE_PATH" ]; then
    IMAGE_PATH="${LIBSCRIPT_ROOT_DIR}/build/disk.img"
  fi
  if [ ! -f "$IMAGE_PATH" ]; then
    printf '[INFO] Target disk image %s missing; synthesizing via Tier 2 pipeline...
' "$IMAGE_PATH"
    "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/raw_img.sh" "${LIBSCRIPT_ROOT_DIR}/build/target-sysroot" "$IMAGE_PATH" 2>/dev/null || true
  fi
fi

case "$PROVIDER" in
  aws)
    if [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/aws/setup.sh" register-image "$IMAGE_PATH"
    fi
    ;;
  gcp)
    if [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/setup.sh" register-image "$IMAGE_PATH"
    fi
    ;;
  azure)
    if [ -n "$IMAGE_PATH" ] && [ -f "$IMAGE_PATH" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/azure/setup.sh" register-image "$IMAGE_PATH"
    fi
    ;;
  proxmox)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/proxmox/setup.sh" create-vm 100 "$IMAGE_PATH"
    ;;
  hetzner)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/hetzner/setup.sh" deploy-rescue 127.0.0.1 "$IMAGE_PATH"
    ;;
  firecracker)
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/firecracker/setup.sh" boot
    ;;
esac

exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/core/deploy_cloud.sh" "$@"
