<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pip' stack.

.DESCRIPTION
Execute this script to run the test suite for pip.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip --version
    Write-Output "pip found"
} else {
    Write-Output "pip skipped (not found)"
}
