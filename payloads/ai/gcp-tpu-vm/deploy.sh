#!/bin/sh
# ## Overview
# Executes a Tier 4 AI training or inference workload on a provisioned GCP Cloud TPU VM.
# Supports --detached, --forward-port, APP_DIR syncing, and HF_TOKEN forwarding.
#
# ## Usage
# ./payloads/ai/gcp-tpu-vm/deploy.sh [--detached] [--forward-port <spec>] [--help]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

for LIB in _lib/_common/pkg_mgr.sh _lib/_common/log.sh; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

# ## print_usage
# Prints usage instructions for gcp-tpu-vm workload deployment.
print_usage() {
  printf '%s
' "Usage: $0 [--detached] [--forward-port <spec>] [--help]"
}

DETACHED_FLAG=""
FORWARD_PORT_FLAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) print_usage; exit 0 ;;
    --detached) DETACHED_FLAG="--detached"; shift ;;
    --forward-port) FORWARD_PORT_FLAG="--forward-port $2"; shift 2 ;;
    *) shift ;;
  esac
done

TPU_NAME="${TPU_NAME:-ml-tpu-vm}"
WORKLOAD_CMD="${WORKLOAD_CMD:-${ML_SCRIPT:-python3 train.py}}"
APP_DIR="${APP_DIR:-${REPO_DIR:-}}"

if [ -n "$APP_DIR" ] && [ -d "$APP_DIR" ]; then
  "${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh" scp "$APP_DIR" "$TPU_NAME:~/workspace" || true
  WORKLOAD_CMD="cd ~/workspace && $WORKLOAD_CMD"
fi

if [ -n "${HF_TOKEN:-}" ]; then
  WORKLOAD_CMD="export HF_TOKEN='${HF_TOKEN}'; $WORKLOAD_CMD"
fi

log_info "Dispatching Tier 4 AI workload to TPU VM ${TPU_NAME}..."
# shellcheck disable=SC2086
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh" ssh "$TPU_NAME" $DETACHED_FLAG $FORWARD_PORT_FLAG "$WORKLOAD_CMD"
