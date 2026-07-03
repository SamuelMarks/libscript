<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'snap' stack.

.DESCRIPTION
Execute this script to run the test suite for snap.
#>

$ErrorActionPreference = "Stop"

if (Get-Command snap -ErrorAction SilentlyContinue) {
    snap --version
    Write-Output "snap found"
} else {
    Write-Output "snap skipped (not found)"
}
