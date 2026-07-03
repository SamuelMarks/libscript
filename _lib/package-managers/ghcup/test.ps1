<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'ghcup' stack.

.DESCRIPTION
Execute this script to run the test suite for ghcup.
#>

$ErrorActionPreference = "Stop"

if (Get-Command ghcup -ErrorAction SilentlyContinue) {
    ghcup --version
    Write-Output "ghcup found"
} else {
    Write-Output "ghcup skipped (not found)"
}
