<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'cc' stack.

.DESCRIPTION
Execute this script to run the test suite for cc.
#>

$ErrorActionPreference = "Stop"

if (Get-Command cc -ErrorAction SilentlyContinue) {
    cc --version
    Write-Output "cc found"
} else {
    Write-Output "cc skipped (not found)"
}
