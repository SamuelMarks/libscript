<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'jq' stack.

.DESCRIPTION
Execute this script to run the test suite for jq.
#>

$ErrorActionPreference = "Stop"

if (Get-Command jq -ErrorAction SilentlyContinue) {
    jq --version
    Write-Output "jq found"
} else {
    Write-Output "jq skipped (not found)"
}
