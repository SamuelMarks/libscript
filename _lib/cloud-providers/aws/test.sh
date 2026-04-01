#!/bin/sh
set -e
export DRY_RUN=true
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Testing AWS component in DRY_RUN mode..."

# Test network
VPC_ID=$("$SCRIPT_DIR/cli.sh" network create test-vpc 2>/dev/null | tr -d '\r\n')
echo "Captured VPC_ID: '$VPC_ID'"
if [ "$VPC_ID" != "vpc-12345678" ]; then echo "VPC_ID mismatch"; exit 1; fi

# Test firewall
echo "Running firewall create..."
"$SCRIPT_DIR/cli.sh" firewall create test-sg test-vpc 2>&1 | tee /tmp/aws_test_out
grep "aws ec2 create-security-group" /tmp/aws_test_out

# Test storage
echo "Running storage create..."
"$SCRIPT_DIR/cli.sh" storage create test-bucket 2>&1 | tee /tmp/aws_test_out
grep "aws s3 mb" /tmp/aws_test_out

# Test cleanup
echo "Running cleanup..."
"$SCRIPT_DIR/cli.sh" cleanup 2>&1 | tee /tmp/aws_test_out
grep "aws resourcegroupstaggingapi" /tmp/aws_test_out

echo "AWS tests passed (dry-run)."
