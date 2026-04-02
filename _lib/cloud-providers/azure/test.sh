#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
. "$(dirname "$0")/../../_common/test_base.sh"

#!/bin/sh
set -e
export DRY_RUN=true
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Testing Azure component in DRY_RUN mode..."

# Test network
"$SCRIPT_DIR/cli.sh" network create test-vnet test-rg 2>&1 | grep "az network vnet create"

# Test node
"$SCRIPT_DIR/cli.sh" node create test-vm test-image test-rg 2>&1 | grep "az vm create"

# Test cleanup
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | grep "az resource list"

echo "Azure tests passed (dry-run)."
