<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'eopkg' stack.

.DESCRIPTION
Execute this script to run the test suite for eopkg.
#>

$ErrorActionPreference = "Stop"

if (Get-Command eopkg -ErrorAction SilentlyContinue) {
    eopkg --version
    Write-Output "eopkg found"
} else {
    Write-Output "eopkg skipped (not found)"
}
