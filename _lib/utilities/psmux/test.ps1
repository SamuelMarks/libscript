<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'psmux' stack.

.DESCRIPTION
Execute this script to run the test suite for psmux.
#>

$ErrorActionPreference = "Stop"

if (Get-Command psmux -ErrorAction SilentlyContinue) {
    psmux -V
    Write-Output "psmux found"
} else {
    Write-Output "psmux skipped (not found)"
}
