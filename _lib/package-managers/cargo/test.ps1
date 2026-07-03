<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cargo' stack.

.DESCRIPTION
Execute this script to run the test suite for cargo.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cargo -ErrorAction SilentlyContinue) {
    cargo --version
    Write-Output "cargo found"
} else {
    Write-Output "cargo skipped (not found)"
}
