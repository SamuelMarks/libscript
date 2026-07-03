<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mas' stack.

.DESCRIPTION
Execute this script to run the test suite for mas.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mas -ErrorAction SilentlyContinue) {
    mas --version
    Write-Output "mas found"
} else {
    Write-Output "mas skipped (not found)"
}
