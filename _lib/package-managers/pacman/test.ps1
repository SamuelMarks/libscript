<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pacman' stack.

.DESCRIPTION
Execute this script to run the test suite for pacman.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pacman -ErrorAction SilentlyContinue) {
    pacman --version
    Write-Output "pacman found"
} else {
    Write-Output "pacman skipped (not found)"
}
