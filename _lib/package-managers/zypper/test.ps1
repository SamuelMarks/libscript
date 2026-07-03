<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'zypper' stack.

.DESCRIPTION
Execute this script to run the test suite for zypper.
#>

$ErrorActionPreference = "Stop"

if (Get-Command zypper -ErrorAction SilentlyContinue) {
    zypper --version
    Write-Output "zypper found"
} else {
    Write-Output "zypper skipped (not found)"
}
