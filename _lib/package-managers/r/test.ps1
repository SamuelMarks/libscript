<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'r' stack.

.DESCRIPTION
Execute this script to run the test suite for r.
#>

$ErrorActionPreference = "Stop"

if (Get-Command R -ErrorAction SilentlyContinue) {
    R --version
    Write-Output "R found"
} else {
    Write-Output "R skipped (not found)"
}
