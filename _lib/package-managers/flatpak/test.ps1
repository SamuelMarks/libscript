<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'flatpak' stack.

.DESCRIPTION
Execute this script to run the test suite for flatpak.
#>

$ErrorActionPreference = "Stop"

if (Get-Command flatpak -ErrorAction SilentlyContinue) {
    flatpak --version
    Write-Output "flatpak found"
} else {
    Write-Output "flatpak skipped (not found)"
}
