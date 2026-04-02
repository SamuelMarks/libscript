#!/bin/sh
. "$(dirname "$0")/../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../_common/test_base.sh"

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
