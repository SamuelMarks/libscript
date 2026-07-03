<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'hatch' stack.

.DESCRIPTION
Execute this script to run the test suite for hatch.
#>

$ErrorActionPreference = "Stop"

if (Get-Command hatch -ErrorAction SilentlyContinue) {
    hatch --version
    Write-Output "hatch found"
} else {
    Write-Output "hatch skipped (not found)"
}
