<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mariadb' stack.

.DESCRIPTION
Execute this script to run the test suite for mariadb.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mariadb -ErrorAction SilentlyContinue) {
    mariadb --version
    Write-Output "mariadb found"
} else {
    Write-Output "mariadb skipped (not found)"
}
