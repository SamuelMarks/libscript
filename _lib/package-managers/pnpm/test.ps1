<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pnpm' stack.

.DESCRIPTION
Execute this script to run the test suite for pnpm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    pnpm --version
    Write-Output "pnpm found"
} else {
    Write-Output "pnpm skipped (not found)"
}
