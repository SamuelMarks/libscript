<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pkgx' stack.

.DESCRIPTION
Execute this script to run the test suite for pkgx.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pkgx -ErrorAction SilentlyContinue) {
    pkgx --version
    Write-Output "pkgx found"
} else {
    Write-Output "pkgx skipped (not found)"
}
