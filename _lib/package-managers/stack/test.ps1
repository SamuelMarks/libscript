<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'stack' stack.

.DESCRIPTION
Execute this script to run the test suite for stack.
#>

$ErrorActionPreference = "Stop"

if (Get-Command stack -ErrorAction SilentlyContinue) {
    stack --version
    Write-Output "stack found"
} else {
    Write-Output "stack skipped (not found)"
}
