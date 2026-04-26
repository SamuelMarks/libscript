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

echo "Testing Unified Cloud Wrapper in DRY_RUN mode..."

# Test routing to AWS (capturing stderr for DRY_RUN log)
"$SCRIPT_DIR/cli.sh" aws storage create test-bucket 2>&1 | grep "aws s3 mb"

# Test global list-managed (capturing stdout which has the headings)
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- AWS Resources"
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- Azure Resources"
"$SCRIPT_DIR/cli.sh" list-managed | grep -e "--- GCP Resources"

# Test global cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up aws..."
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up azure..."
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "Cleaning up gcp..."

echo "Unified Cloud Wrapper tests passed (dry-run)."
