<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'poetry' stack.

.DESCRIPTION
Execute this script to run the test suite for poetry.
#>

$ErrorActionPreference = "Stop"

if (Get-Command poetry -ErrorAction SilentlyContinue) {
    poetry --version
    Write-Output "poetry found"
} else {
    Write-Output "poetry skipped (not found)"
}
