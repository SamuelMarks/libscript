#!/bin/sh
set -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PACKAGE_NAME="aria2"
. "$SCRIPT_DIR/../../_common/cli.sh"
