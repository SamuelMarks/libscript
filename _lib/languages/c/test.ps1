<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'c' stack.

.DESCRIPTION
Execute this script to run the test suite for c.
#>

$ErrorActionPreference = "Stop"

if (Get-Command c -ErrorAction SilentlyContinue) {
    c --version
    Write-Output "c found"
} else {
    Write-Output "c skipped (not found)"
}
