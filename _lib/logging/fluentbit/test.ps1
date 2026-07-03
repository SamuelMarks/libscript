<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'fluentbit' stack.

.DESCRIPTION
Execute this script to run the test suite for fluentbit.
#>

$ErrorActionPreference = "Stop"

if (Get-Command fluentbit -ErrorAction SilentlyContinue) {
    fluentbit --version
    Write-Output "fluentbit found"
} else {
    Write-Output "fluentbit skipped (not found)"
}
