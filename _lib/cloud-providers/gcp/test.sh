#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
for lib in '_lib/_common/test_base.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
for lib in '_lib/_common/test_base.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

#!/bin/sh
set -e
export DRY_RUN=true
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Testing GCP component in DRY_RUN mode..."

# Test network
"$SCRIPT_DIR/cli.sh" network create test-net 2>&1 | grep "gcloud compute networks create"

# Test node
"$SCRIPT_DIR/cli.sh" node create test-node test-family test-project 2>&1 | grep "gcloud compute instances create"

# Test cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "gcloud compute instances list"

echo "GCP tests passed (dry-run)."
