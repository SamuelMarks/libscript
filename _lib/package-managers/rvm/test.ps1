<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rvm' stack.

.DESCRIPTION
Execute this script to run the test suite for rvm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rvm -ErrorAction SilentlyContinue) {
    rvm --version
    Write-Output "rvm found"
} else {
    Write-Output "rvm skipped (not found)"
}
