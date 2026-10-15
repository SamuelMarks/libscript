#!/bin/sh
# ## Overview
# Prepares the local environment and idempotently provisions the GKE XPK training cluster.
#
# ## Usage
# ./payloads/ai/gke-xpk-training/setup.sh [--help]

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
# Prints command usage help for gke-xpk-training setup.sh.
print_usage() {
  printf '%s\n' "Usage: $0 [--help]"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

libscript_depends "gcp-cli" "python" "kubectl" "xpk"

CLUSTER_NAME="${XPK_CLUSTER_NAME:-ml-xpk-cluster}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"
GCP_ZONE="${GCP_ZONE:-}"

if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_ZONE" ]; then
  log_info "GCP_PROJECT_ID and GCP_ZONE not specified. Staging complete."
  exit 0
fi

"${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-cli/cli.sh" auth

if gcloud container clusters describe "$CLUSTER_NAME" --zone="$GCP_ZONE" --project="$GCP_PROJECT_ID" >/dev/null 2>&1; then
  log_info "GKE cluster $CLUSTER_NAME already exists in $GCP_ZONE. Skipping creation."
else
  log_info "Provisioning XPK cluster: $CLUSTER_NAME..."
  xpk cluster create \
    --cluster "$CLUSTER_NAME" \
    --tpu-type "${TPU_ACCELERATOR_TYPE:-v4-8}" \
    --project "$GCP_PROJECT_ID" \
    --zone "$GCP_ZONE"
fi
log_info "Setup complete."
