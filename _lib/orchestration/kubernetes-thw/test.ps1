# ## Overview
# Test suite for the kubernetes-thw component.
#
# ## Usage
# Execute this script to perform a component-specific test.

$ErrorActionPreference = "Stop"

sh "$PSScriptRoot/test.sh"
exit $LASTEXITCODE
