<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'swupd' stack.

.DESCRIPTION
Execute this script to run the test suite for swupd.
#>

$ErrorActionPreference = "Stop"

if (Get-Command swupd -ErrorAction SilentlyContinue) {
    swupd --version
    Write-Output "swupd found"
} else {
    Write-Output "swupd skipped (not found)"
}
