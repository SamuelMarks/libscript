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
