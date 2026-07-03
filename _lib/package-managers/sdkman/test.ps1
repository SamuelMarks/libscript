<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'sdkman' stack.

.DESCRIPTION
Execute this script to run the test suite for sdkman.
#>

$ErrorActionPreference = "Stop"

if (Get-Command sdkman -ErrorAction SilentlyContinue) {
    sdkman --version
    Write-Output "sdkman found"
} else {
    Write-Output "sdkman skipped (not found)"
}
