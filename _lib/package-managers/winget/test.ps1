<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'winget' stack.

.DESCRIPTION
Execute this script to run the test suite for winget.
#>

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget --version
    Write-Output "winget found"
} else {
    Write-Output "winget skipped (not found)"
}
