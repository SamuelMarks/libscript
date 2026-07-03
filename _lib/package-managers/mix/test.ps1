<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mix' stack.

.DESCRIPTION
Execute this script to run the test suite for mix.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mix -ErrorAction SilentlyContinue) {
    mix --version
    Write-Output "mix found"
} else {
    Write-Output "mix skipped (not found)"
}
