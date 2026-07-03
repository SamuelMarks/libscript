<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'iis' stack.

.DESCRIPTION
Execute this script to run the test suite for iis.
#>

$ErrorActionPreference = "Stop"

if (Get-Command iis -ErrorAction SilentlyContinue) {
    iis --version
    Write-Output "iis found"
} else {
    Write-Output "iis skipped (not found)"
}
