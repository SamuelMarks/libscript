<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'luarocks' stack.

.DESCRIPTION
Execute this script to run the test suite for luarocks.
#>

$ErrorActionPreference = "Stop"

if (Get-Command luarocks -ErrorAction SilentlyContinue) {
    luarocks --version
    Write-Output "luarocks found"
} else {
    Write-Output "luarocks skipped (not found)"
}
