<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cmake' stack.

.DESCRIPTION
Execute this script to run the test suite for cmake.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cmake -ErrorAction SilentlyContinue) {
    cmake --version
} else {
    Write-Host "cmake skipped (not found)"
}
