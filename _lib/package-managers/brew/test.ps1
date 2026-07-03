<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'brew' stack.

.DESCRIPTION
Execute this script to run the test suite for brew.
#>

$ErrorActionPreference = "Stop"

if (Get-Command brew -ErrorAction SilentlyContinue) {
    brew --version
    Write-Output "brew found"
} else {
    Write-Output "brew skipped (not found)"
}
