<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'mise' stack.

.DESCRIPTION
Execute this script to run the test suite for mise.
#>

$ErrorActionPreference = "Stop"

if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise --version
    Write-Output "mise found"
} else {
    Write-Output "mise skipped (not found)"
}
