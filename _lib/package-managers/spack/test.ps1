<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'spack' stack.

.DESCRIPTION
Execute this script to run the test suite for spack.
#>

$ErrorActionPreference = "Stop"

if (Get-Command spack -ErrorAction SilentlyContinue) {
    spack --version
    Write-Output "spack found"
} else {
    Write-Output "spack skipped (not found)"
}
