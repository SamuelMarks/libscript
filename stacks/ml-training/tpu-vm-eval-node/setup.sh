#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the TPU VM evaluation node for ML stack.
# 
# ## Usage
# Execute this script to install and configure tpu-vm-eval-node on the local system.


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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0"
  printf '%s\n' "See README.md for details."
  exit 0
fi

TPU_NAME="${TPU_NAME:-ml-eval-node}"
TPU_DATA_DISK_SIZE="${TPU_DATA_DISK_SIZE:-200}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

printf '%s\n' "Setting up Comprehensive ML Training Stack on $TPU_NAME..."

gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

printf '%s\n' "Provisioning TPU VM with $TPU_DATA_DISK_SIZE GB persistent disk..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/tpu-vm/cli.sh" create "$TPU_NAME"

printf '%s\n' "Setup complete."
