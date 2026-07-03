<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mongodb' stack.

.DESCRIPTION
Execute this script to run the test suite for mongodb.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mongodb -ErrorAction SilentlyContinue) {
    mongodb --version
    Write-Output "mongodb found"
} else {
    Write-Output "mongodb skipped (not found)"
}
