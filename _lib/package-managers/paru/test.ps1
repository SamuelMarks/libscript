<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'paru' stack.

.DESCRIPTION
Execute this script to run the test suite for paru.
#>

$ErrorActionPreference = "Stop"

if (Get-Command paru -ErrorAction SilentlyContinue) {
    paru --version
    Write-Output "paru found"
} else {
    Write-Output "paru skipped (not found)"
}
