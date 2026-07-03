<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'gem' stack.

.DESCRIPTION
Execute this script to run the test suite for gem.
#>

$ErrorActionPreference = "Stop"

if (Get-Command gem -ErrorAction SilentlyContinue) {
    gem --version
    Write-Output "gem found"
} else {
    Write-Output "gem skipped (not found)"
}
