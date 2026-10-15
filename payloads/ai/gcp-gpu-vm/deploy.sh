#!/bin/sh
# ## Overview
# Executes a Tier 4 CUDA model-serving or training workload on a provisioned GCP GPU VM.
#
# ## Usage
# ./payloads/ai/gcp-gpu-vm/deploy.sh [--help]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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
# Prints usage instructions for gcp-gpu-vm workload deployment.
print_usage() {
  printf '%s\n' "Usage: $0 [--help]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

GPU_NAME="${GPU_NAME:-ml-gpu-vm}"
WORKLOAD_CMD="${WORKLOAD_CMD:-python3 -m vllm.entrypoints.openai.api_server --port 8000}"
log_info "Dispatching Tier 4 AI workload to GPU VM ${GPU_NAME}..."
"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-gpu-vm/cli.sh" ssh "$GPU_NAME" "$WORKLOAD_CMD"
