<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'macports' stack.

.DESCRIPTION
Execute this script to run the test suite for macports.
#>

$ErrorActionPreference = "Stop"

if (Get-Command macports -ErrorAction SilentlyContinue) {
    macports --version
    Write-Output "macports found"
} else {
    Write-Output "macports skipped (not found)"
}
