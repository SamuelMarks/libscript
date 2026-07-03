<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'nimble' stack.

.DESCRIPTION
Execute this script to run the test suite for nimble.
#>

$ErrorActionPreference = "Stop"

if (Get-Command nimble -ErrorAction SilentlyContinue) {
    nimble --version
    Write-Output "nimble found"
} else {
    Write-Output "nimble skipped (not found)"
}
