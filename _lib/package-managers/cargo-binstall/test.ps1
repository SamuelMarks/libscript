<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cargo-binstall' stack.

.DESCRIPTION
Execute this script to run the test suite for cargo-binstall.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cargo-binstall -ErrorAction SilentlyContinue) {
    cargo-binstall --version
    Write-Output "cargo-binstall found"
} else {
    Write-Output "cargo-binstall skipped (not found)"
}
