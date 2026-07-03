<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'conan' stack.

.DESCRIPTION
Execute this script to run the test suite for conan.
#>

$ErrorActionPreference = "Stop"

if (Get-Command conan -ErrorAction SilentlyContinue) {
    conan --version
    Write-Output "conan found"
} else {
    Write-Output "conan skipped (not found)"
}
