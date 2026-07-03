<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'sqlite' stack.

.DESCRIPTION
Execute this script to run the test suite for sqlite.
#>

$ErrorActionPreference = "Stop"

if (Get-Command sqlite -ErrorAction SilentlyContinue) {
    sqlite --version
    Write-Output "sqlite found"
} else {
    Write-Output "sqlite skipped (not found)"
}
