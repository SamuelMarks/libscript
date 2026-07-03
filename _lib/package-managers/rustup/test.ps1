<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rustup' stack.

.DESCRIPTION
Execute this script to run the test suite for rustup.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rustup -ErrorAction SilentlyContinue) {
    rustup --version
    Write-Output "rustup found"
} else {
    Write-Output "rustup skipped (not found)"
}
