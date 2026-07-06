#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the TPU VM vLLM AI serving stack stack.
# 
# ## Usage
# Execute this script to install and configure tpu-vm-vllm on the local system.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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

# Walk up to find root
_root="$SCRIPT_DIR"
while [ ! -f "$_root/ROOT" ] && [ "$_root" != "/" ]; do
    _root=$(dirname "$_root")
done
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$_root}"

set -feu
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0"
  printf '%s\n' "See README.md for details."
  exit 0
fi


# Setup Script: Authenticate GCP -> Check for/Create TPU VM in specified zone.

TPU_NAME="${TPU_NAME:-ml-tpu-vm}"

GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
TPU_ZONE="${TPU_ZONE:-}"
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$TPU_ZONE" ]; then
  printf '%s\n' "[ERROR] GCP_PROJECT_ID and TPU_ZONE must be explicitly specified."
  exit 1
fi

printf '%s\n' "Setting up TPU VM Prototyping Stack..."

# Authenticate GCP is handled by the cli component installation if not authenticated,
# but we can explicitly call it.
gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login

printf '%s\n' "Creating TPU VM $TPU_NAME..."
"${LIBSCRIPT_ROOT_DIR}/installed/gcp-cli/bin/tpu-vm-cli" create "$TPU_NAME" || \
  "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp/tpu-vm/cli.sh" create "$TPU_NAME"

printf '%s\n' "Setup complete."
