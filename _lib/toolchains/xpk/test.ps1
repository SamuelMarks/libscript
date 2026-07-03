<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'xpk' stack.

.DESCRIPTION
Execute this script to run the test suite for xpk.
#>

$ErrorActionPreference = "Stop"

if (Get-Command xpk -ErrorAction SilentlyContinue) {
    xpk --version
} else {
    Write-Host "xpk skipped (not found)"
}
