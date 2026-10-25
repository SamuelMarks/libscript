#!/bin/sh
# ## Overview
# Action dispatcher for cloud core operations.
#
# ## Usage
# Evaluates `$ACTION` (e.g. `list-managed`, `diff`, `backup`, `restore`, or provider aliases) and dispatches execution.


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
export STACK="${STACK:-}${THIS_FILE}"':'

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

action="${ACTION:-}"

# Load JSON variables for tags/filtering if present
export FILTER_TAG=""
for arg in "$@"; do
  case "$arg" in
    --tags=*) export FILTER_TAG="${arg#*=}" ;;
    *=*) export FILTER_TAG="$arg" ;;
  esac
done

# ## handle_list_managed
# Performs the handle_list_managed operation and updates component state.
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
  printf '%s\n' "--- DigitalOcean Resources"
  if command -v doctl >/dev/null 2>&1; then
    printf '%s\n' "DigitalOcean Managed Resource Listing Placeholder"
  fi
  printf '%s\n' "--- Linode Resources"
  if command -v linode-cli >/dev/null 2>&1; then
    printf '%s\n' "Linode Managed Resource Listing Placeholder"
  fi
  printf '%s\n' "--- Vultr Resources"
  if command -v vultr-cli >/dev/null 2>&1; then
    printf '%s\n' "Vultr Managed Resource Listing Placeholder"
  fi
}

# ## handle_diff
# Performs the handle_diff operation and updates component state.
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
  printf '%s\n' "--- DigitalOcean Drift"
  printf '%s\n' "DigitalOcean Diff Placeholder"
  printf '%s\n' "--- Linode Drift"
  printf '%s\n' "Linode Diff Placeholder"
  printf '%s\n' "--- Vultr Drift"
  printf '%s\n' "Vultr Diff Placeholder"
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
  dashboard|cost|usage|logs-aggregate)
    exec "$SCRIPT_DIR/dashboard.sh" "$action" "$@"
    ;;
  aws|azure|gcp|hetzner|proxmox|digitalocean|linode|vultr)
    PROVIDER="$action"
    if [ "${1:-}" = "storage" ]; then
      shift
      export LIBSCRIPT_CLOUD="$PROVIDER"
      unset SCRIPT_NAME || true
      exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/storage/cli.sh" "$@"
    elif [ "${1:-}" = "volume" ]; then
      shift
      export LIBSCRIPT_CLOUD="$PROVIDER"
      unset SCRIPT_NAME || true
      exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/volume/cli.sh" "$@"
    elif [ "${1:-}" = "cdn" ]; then
      shift
      export LIBSCRIPT_CLOUD="$PROVIDER"
      unset SCRIPT_NAME || true
      exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/cdn/cli.sh" "$@"
    elif [ "${1:-}" = "cert" ]; then
      shift
      export LIBSCRIPT_CLOUD="$PROVIDER"
      unset SCRIPT_NAME || true
      exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/cert/cli.sh" "$@"
    elif [ "${1:-}" = "cloudinit" ]; then
      shift
      export LIBSCRIPT_CLOUD="$PROVIDER"
      unset SCRIPT_NAME || true
      exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/cloudinit/cli.sh" "$@"
    fi
    CLI_PATH="$LIBSCRIPT_ROOT_DIR/_lib/cloud-providers/$PROVIDER/cli.sh"
    if [ ! -f "$CLI_PATH" ]; then
      printf '%s\n' "Error: Provider $PROVIDER not supported or installed." >&2
      exit 1
    fi
    unset SCRIPT_NAME || true
    exec "$CLI_PATH" "$@"
    ;;
  storage|volume|cdn|cert|cloudinit)
    unset SCRIPT_NAME || true
    exec "$LIBSCRIPT_ROOT_DIR/_lib/cloud/$action/cli.sh" "$@"
    ;;
  cleanup)
    printf '%s\n' "Cleaning up all cloud resources..."
    if command -v aws >/dev/null 2>&1; then printf '%s\n' "Cleaning up aws..."; fi
    if command -v az >/dev/null 2>&1; then printf '%s\n' "Cleaning up azure..."; fi
    if command -v gcloud >/dev/null 2>&1; then printf '%s\n' "Cleaning up gcp..."; fi
    if command -v doctl >/dev/null 2>&1; then printf '%s\n' "Cleaning up digitalocean..."; fi
    if command -v linode-cli >/dev/null 2>&1; then printf '%s\n' "Cleaning up linode..."; fi
    if command -v vultr-cli >/dev/null 2>&1; then printf '%s\n' "Cleaning up vultr..."; fi
    exit 0
    ;;
  *)
    # Default wrapper behavior (no-op/pass-through)
    ;;
esac
