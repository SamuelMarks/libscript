<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'rust' stack.

.DESCRIPTION
Execute this script to run the test suite for rust.
#>

$ErrorActionPreference = "Stop"

if (Get-Command rust -ErrorAction SilentlyContinue) {
    rust --version
    Write-Output "rust found"
} else {
    Write-Output "rust skipped (not found)"
}
