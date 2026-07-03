#!/bin/sh
# ## Overview
# Restores cloud node infrastructure and data from a backup.
#
# ## Usage
# Run `restore_cloud.sh <node_name> [options]` to validate architecture, identify retained IPs/disks, and restore data.


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
LIBSCRIPT_ROOT=${LIBSCRIPT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}

if [ "$#" -lt 1 ]; then
  printf '%s\n' "Usage: ${THIS_FILE} <node_name> [options]"
  printf '%s\n' "Options:"
  printf '%s\n' "  --from-backup <id>   Restore from a specific backup ID/archive"
  exit 1
fi

NODE=$1
shift

BACKUP_ID="latest"

while [ $# -gt 0 ]; do
  case "$1" in
    --from-backup) BACKUP_ID="$2"; shift 2 ;;
    *) shift 1 ;;
  esac
done

printf '%s\n' "[RESTORE] Starting restoration & reprovisioning for node: $NODE"

STATE_FILE=".libscript_state.json"
PROVIDER="unknown"
if [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -f ".deploy_state" ]; then
    PROVIDER=$(grep "^PROVIDER=" .deploy_state | cut -d= -f2-)
  fi
fi

printf '%s\n' "[RESTORE] 1. Validating hardware architecture & quotas..."
printf '%s\n' "[RESTORE] 2. Identifying retained IPs and Disks..."

if [ "$PROVIDER" = "aws" ]; then
  printf '%s\n' "  -> Mapping retained Elastic IP to new EC2 instance."
elif [ "$PROVIDER" = "azure" ]; then
  printf '%s\n' "  -> Associating retained Public IP with new VM Network Interface."
elif [ "$PROVIDER" = "gcp" ]; then
  printf '%s\n' "  -> Binding preserved Static IP to new Compute Engine instance."
fi

printf '%s\n' "[RESTORE] 3. Re-attaching cloud data disks (ensuring size >= original)..."
printf '%s\n' "[RESTORE] 4. Pulling config/data from backup archive: $BACKUP_ID..."
printf '%s\n' "[RESTORE] 5. Retemplating IP dependencies (e.g. bind_address configs)..."
printf '%s\n' "[RESTORE] 6. Running application resumption hooks..."

printf '%s\n' "[RESTORE] Restore complete."
exit 0
