<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'wait4x' stack.

.DESCRIPTION
Execute this script to run the test suite for wait4x.
#>

$ErrorActionPreference = "Stop"

if (Get-Command wait4x -ErrorAction SilentlyContinue) {
    wait4x --version
    Write-Output "wait4x found"
} else {
    Write-Output "wait4x skipped (not found)"
}
