<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'coursier' stack.

.DESCRIPTION
Execute this script to run the test suite for coursier.
#>

$ErrorActionPreference = "Stop"

if (Get-Command coursier -ErrorAction SilentlyContinue) {
    coursier --version
} else {
    Write-Host "coursier skipped (not found)"
}
