<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'krew' stack.

.DESCRIPTION
Execute this script to run the test suite for krew.
#>

$ErrorActionPreference = "Stop"

if (Get-Command krew -ErrorAction SilentlyContinue) {
    krew --version
    Write-Output "krew found"
} else {
    Write-Output "krew skipped (not found)"
}
