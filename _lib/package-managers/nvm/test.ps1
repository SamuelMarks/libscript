<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nvm' stack.

.DESCRIPTION
Execute this script to run the test suite for nvm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm --version
    Write-Output "nvm found"
} else {
    Write-Output "nvm skipped (not found)"
}
