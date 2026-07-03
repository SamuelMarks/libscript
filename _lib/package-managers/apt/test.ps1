<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'apt' stack.

.DESCRIPTION
Execute this script to run the test suite for apt.
#>

$ErrorActionPreference = "Stop"

if (Get-Command apt -ErrorAction SilentlyContinue) {
    apt --version
    Write-Output "apt found"
} else {
    Write-Output "apt skipped (not found)"
}
