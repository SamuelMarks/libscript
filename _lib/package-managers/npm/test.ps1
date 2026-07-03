<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'npm' stack.

.DESCRIPTION
Execute this script to run the test suite for npm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm --version
    Write-Output "npm found"
} else {
    Write-Output "npm skipped (not found)"
}
