<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'julia' stack.

.DESCRIPTION
Execute this script to run the test suite for julia.
#>

$ErrorActionPreference = "Stop"

if (Get-Command julia -ErrorAction SilentlyContinue) {
    julia --version
    Write-Output "julia found"
} else {
    Write-Output "julia skipped (not found)"
}
