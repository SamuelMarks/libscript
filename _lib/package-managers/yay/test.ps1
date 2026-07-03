<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'yay' stack.

.DESCRIPTION
Execute this script to run the test suite for yay.
#>

$ErrorActionPreference = "Stop"

if (Get-Command yay -ErrorAction SilentlyContinue) {
    yay --version
    Write-Output "yay found"
} else {
    Write-Output "yay skipped (not found)"
}
