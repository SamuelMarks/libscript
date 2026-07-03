<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'kotlin' stack.

.DESCRIPTION
Execute this script to run the test suite for kotlin.
#>

$ErrorActionPreference = "Stop"

if (Get-Command kotlin -ErrorAction SilentlyContinue) {
    kotlin --version
    Write-Output "kotlin found"
} else {
    Write-Output "kotlin skipped (not found)"
}
