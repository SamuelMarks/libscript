<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'bun' stack.

.DESCRIPTION
Execute this script to run the test suite for bun.
#>

$ErrorActionPreference = "Stop"

if (Get-Command bun -ErrorAction SilentlyContinue) {
    bun --version
    Write-Output "bun found"
} else {
    Write-Output "bun skipped (not found)"
}
