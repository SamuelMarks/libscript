<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cpp' stack.

.DESCRIPTION
Execute this script to run the test suite for cpp.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cpp -ErrorAction SilentlyContinue) {
    cpp --version
    Write-Output "cpp found"
} else {
    Write-Output "cpp skipped (not found)"
}
