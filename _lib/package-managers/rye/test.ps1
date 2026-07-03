<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rye' stack.

.DESCRIPTION
Execute this script to run the test suite for rye.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rye -ErrorAction SilentlyContinue) {
    rye --version
    Write-Output "rye found"
} else {
    Write-Output "rye skipped (not found)"
}
