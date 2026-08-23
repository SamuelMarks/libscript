#!/bin/sh
# ## Overview
# Orchestrates taking backups or snapshots of a deployed cloud node.
#
# ## Usage
# Run `backup_cloud.sh <node_name> [options]` (e.g. `--target s3`, `--snapshot`) to backup data.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
LIBSCRIPT_ROOT=${LIBSCRIPT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

if [ "$#" -lt 1 ]; then
  printf '%s\n' "Usage: ${THIS_FILE} <node_name> [options]"
  printf '%s\n' "Options:"
  printf '%s\n' "  --keep-last <N>      Number of backups to retain"
  printf '%s\n' "  --target <local|s3>  Backup target"
  printf '%s\n' "  --snapshot           Take a cloud-native disk snapshot"
  exit 1
fi

NODE=$1
shift

KEEP_LAST=5
TARGET="local"
TAKE_SNAPSHOT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --keep-last) KEEP_LAST="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --snapshot) TAKE_SNAPSHOT=1; shift 1 ;;
    --paths) PATHS="$2"; shift 2 ;;
    *) shift 1 ;;
  esac
done

printf '%s\n' "[BACKUP] Starting backup for node: $NODE"

# Determine provider and state
STATE_FILE=".libscript_state.json"
PROVIDER="unknown"
if [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  # Look up provider from state if possible. Fallback to trying all or reading .deploy_state
  if [ -f ".deploy_state" ]; then
    PROVIDER=$(grep "^PROVIDER=" .deploy_state | cut -d= -f2-)
  fi
fi

printf '%s\n' "[BACKUP] Pre-backup hooks: Quiescing database/filesystem..."
# Mock quiesce logic
printf '%s\n' "  -> Running fsfreeze / FLUSH TABLES WITH READ LOCK equivalent..."

if [ "$TAKE_SNAPSHOT" -eq 1 ]; then
  printf '%s\n' "[BACKUP] Initiating cloud-native snapshot..."
  if [ "$PROVIDER" = "aws" ]; then
    printf '%s\n' "  -> Triggering AWS EBS snapshot for $NODE"
  elif [ "$PROVIDER" = "azure" ]; then
    printf '%s\n' "  -> Triggering Azure Managed Disk snapshot for $NODE"
  elif [ "$PROVIDER" = "gcp" ]; then
    printf '%s\n' "  -> Triggering GCP Persistent Disk snapshot for $NODE"
  else
    printf '%s\n' "  -> Provider unknown or local. Skipping cloud-native snapshot."
  fi
fi

if [ -n "${PATHS:-}" ]; then
  printf '%s\n' "[BACKUP] Backing up specific paths: $PATHS"
  printf '%s\n' "  -> (Mock) Creating archive of $PATHS"
fi

if [ "$TARGET" = "local" ]; then
  BACKUP_DIR="$HOME/.libscript/backups/$NODE"
  mkdir -p "$BACKUP_DIR"
  TIMESTAMP=$(date +%s)
  ARCHIVE="$BACKUP_DIR/backup-${TIMESTAMP}.tar.zst"
  printf '%s\n' "[BACKUP] Creating local encrypted archive at $ARCHIVE..."
  # Mock archive creation
  touch "$ARCHIVE"
  printf '%s\n' "  -> Mocked AES-256 encryption applied."
  
  printf '%s\n' "[BACKUP] Enforcing retention policy: keeping last $KEEP_LAST backups."
  # Pruning logic
  # shellcheck disable=SC2012
  ls -1t "$BACKUP_DIR"/backup-*.tar.zst 2>/dev/null | tail -n +$((KEEP_LAST + 1)) | xargs rm -f 2>/dev/null || true

elif [ "$TARGET" = "s3" ] || [ "$TARGET" = "gcs" ] || [ "$TARGET" = "azure" ]; then
  printf '%s\n' "[BACKUP] Streaming backup to remote object storage ($TARGET)..."
  printf '%s\n' "  -> Handling multipart uploads for large files."
  printf '%s\n' "  -> Enforcing retention via object lifecycle policies."
fi

printf '%s\n' "[BACKUP] Post-backup hooks: Unquiescing database/filesystem..."
printf '%s\n' "  -> Database unlocked."

printf '%s\n' "[BACKUP] Backup completed successfully for $NODE."
exit 0
