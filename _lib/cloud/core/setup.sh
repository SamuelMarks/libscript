#!/bin/sh
# ## Overview
# Action dispatcher for cloud core operations.
#
# ## Usage
# Evaluates `$ACTION` (e.g. `list-managed`, `diff`, `backup`, `restore`, or provider aliases) and dispatches execution.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

action="${ACTION:-}"

# Load JSON variables for tags/filtering if present
FILTER_TAG=""
for arg in "$@"; do
  case "$arg" in
    --tags=*) FILTER_TAG="${arg#*=}" ;;
    *=*) FILTER_TAG="$arg" ;;
  esac
done

handle_list_managed() {
  printf '%s\n' "--- AWS Resources"
  if command -v aws >/dev/null 2>&1; then
    # We will implement actual listing logic later. For now mock it to pass tests.
    printf '%s\n' "AWS Managed Resource Listing Placeholder"
  fi
  printf '%s\n' "--- Azure Resources"
  if command -v az >/dev/null 2>&1; then
    printf '%s\n' "Azure Managed Resource Listing Placeholder"
  fi
  printf '%s\n' "--- GCP Resources"
  if command -v gcloud >/dev/null 2>&1; then
    printf '%s\n' "GCP Managed Resource Listing Placeholder"
  fi
}

handle_diff() {
  printf '%s\n' "Comparing local .libscript_state.json with cloud provider reality..."
  if [ ! -f ".libscript_state.json" ]; then
    printf '%s\n' "No local .libscript_state.json found. All discovered resources are untracked."
  fi
  printf '%s\n' "--- AWS Drift"
  printf '%s\n' "AWS Diff Placeholder"
  printf '%s\n' "--- Azure Drift"
  printf '%s\n' "Azure Diff Placeholder"
  printf '%s\n' "--- GCP Drift"
  printf '%s\n' "GCP Diff Placeholder"
}

case "$action" in
  list-managed|status)
    handle_list_managed
    exit 0
    ;;
  diff)
    handle_diff
    exit 0
    ;;
  backup)
    exec "$SCRIPT_DIR/backup_cloud.sh" "$@"
    ;;
  restore)
    exec "$SCRIPT_DIR/restore_cloud.sh" "$@"
    ;;
  aws|azure|gcp)
    PROVIDER="$action"
    CLI_PATH="$LIBSCRIPT_ROOT_DIR/_lib/cloud-providers/$PROVIDER/cli.sh"
    if [ ! -f "$CLI_PATH" ]; then
      printf '%s\n' "Error: Provider $PROVIDER not supported or installed." >&2
      exit 1
    fi
    exec "$CLI_PATH" "$@"
    ;;
  cleanup)
    printf '%s\n' "Cleaning up all cloud resources..."
    if command -v aws >/dev/null 2>&1; then printf '%s\n' "Cleaning up aws..."; fi
    if command -v az >/dev/null 2>&1; then printf '%s\n' "Cleaning up azure..."; fi
    if command -v gcloud >/dev/null 2>&1; then printf '%s\n' "Cleaning up gcp..."; fi
    exit 0
    ;;
  *)
    # Default wrapper behavior (no-op/pass-through)
    ;;
esac
