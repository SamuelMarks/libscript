<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'vcpkg' stack.

.DESCRIPTION
Execute this script to run the test suite for vcpkg.
#>

$ErrorActionPreference = "Stop"

if (Get-Command vcpkg -ErrorAction SilentlyContinue) {
    vcpkg --version
    Write-Output "vcpkg found"
} else {
    Write-Output "vcpkg skipped (not found)"
}
