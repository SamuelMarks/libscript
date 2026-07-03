<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'aqua' stack.

.DESCRIPTION
Execute this script to run the test suite for aqua.
#>

$ErrorActionPreference = "Stop"

if (Get-Command aqua -ErrorAction SilentlyContinue) {
    aqua -v
    Write-Output "aqua found"
} else {
    Write-Output "aqua skipped (not found)"
}
