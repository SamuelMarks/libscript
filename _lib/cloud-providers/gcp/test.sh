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
for LIB in '_lib/_common/test_base.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
for LIB in '_lib/_common/test_base.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
export DRY_RUN=true
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

log_info "Testing GCP component in DRY_RUN mode..."

# Test network
"$SCRIPT_DIR/cli.sh" network create test-net 2>&1 | grep "gcloud compute networks create"

# Test node
"$SCRIPT_DIR/cli.sh" node create test-node test-family test-project 2>&1 | grep "gcloud compute instances create"

# Test cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "gcloud compute instances list"

log_info "GCP tests passed (dry-run)."
