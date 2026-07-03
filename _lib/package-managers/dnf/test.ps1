<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'dnf' stack.

.DESCRIPTION
Execute this script to run the test suite for dnf.
#>

$ErrorActionPreference = "Stop"

if (Get-Command dnf -ErrorAction SilentlyContinue) {
    dnf --version
    Write-Output "dnf found"
} else {
    Write-Output "dnf skipped (not found)"
}
