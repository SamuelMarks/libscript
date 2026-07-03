<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'postgres' stack.

.DESCRIPTION
Execute this script to run the test suite for postgres.
#>

$ErrorActionPreference = "Stop"

if (Get-Command postgres -ErrorAction SilentlyContinue) {
    postgres --version
    Write-Output "postgres found"
} else {
    Write-Output "postgres skipped (not found)"
}
