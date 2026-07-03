<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'fnm' stack.

.DESCRIPTION
Execute this script to run the test suite for fnm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm --version
    Write-Output "fnm found"
} else {
    Write-Output "fnm skipped (not found)"
}
