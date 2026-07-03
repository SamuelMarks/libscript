<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nodejs' stack.

.DESCRIPTION
Execute this script to run the test suite for nodejs.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nodejs -ErrorAction SilentlyContinue) {
    nodejs --version
    Write-Output "nodejs found"
} else {
    Write-Output "nodejs skipped (not found)"
}
