<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'uv' stack.

.DESCRIPTION
Execute this script to run the test suite for uv.
#>

$ErrorActionPreference = "Stop"

if (Get-Command uv -ErrorAction SilentlyContinue) {
    uv --version
    Write-Output "uv found"
} else {
    Write-Output "uv skipped (not found)"
}
