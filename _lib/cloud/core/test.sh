#!/bin/sh

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

for LIB in _lib/_common/test_base.sh _lib/_common/log.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME

export DRY_RUN=true
SCRIPT_DIR=$(cd ${SCRIPT_DIR} && pwd)
export LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

export LIBSCRIPT_SKIP_DEPENDENCIES=1

log_info "Testing Unified Cloud Wrapper in DRY_RUN mode..."

# Test global list-managed (capturing stdout which has the headings)
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- AWS Resources"
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- Azure Resources"
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- GCP Resources"

# Test global cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up aws..."
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up azure..."
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up gcp..."

# Test Reprovisioning Lifecycle & Edge Cases
log_info "Testing Multicloud Lifecycle: diff, backup, deprovision, restore..."

# Diff / Drift Detection
"$SCRIPT_DIR/cli.sh" diff | grep -e "Comparing local .libscript_state.json"
"$SCRIPT_DIR/cli.sh" diff | grep -e "--- AWS Drift"

# Backup (Local & S3 targets with edge case --paths parsing)
"$SCRIPT_DIR/cli.sh" backup test-node-azure --keep-last 3 --target local | grep -e "\[BACKUP\] Creating local encrypted archive"
"$SCRIPT_DIR/cli.sh" backup test-node-aws --keep-last 5 --target s3 --snapshot --paths "/var/lib/postgresql/data /etc/letsencrypt" | grep -e "\[BACKUP\] Backing up specific paths:"
"$SCRIPT_DIR/cli.sh" backup test-node-aws --keep-last 5 --target s3 --snapshot --paths "/var/lib/postgresql/data /etc/letsencrypt" | grep -e "\[BACKUP\] Streaming backup to remote object storage"

# Deprovisioning (Retaining IP and Data for Idempotency)
"$LIBSCRIPT_ROOT_DIR/libscript.sh" deprovision aws test-node-aws test-vpc us-east-1 --retain-ip --retain-data 2>&1 | grep -e "Retaining IP address"
"$LIBSCRIPT_ROOT_DIR/libscript.sh" deprovision aws test-node-aws test-vpc us-east-1 --retain-ip --retain-data 2>&1 | grep -e "Retaining data volume"

# Restoration
"$SCRIPT_DIR/cli.sh" restore test-node-aws --from-backup latest | grep -e "\[RESTORE\] Starting restoration"

log_info "Unified Cloud Wrapper tests passed (dry-run)."
