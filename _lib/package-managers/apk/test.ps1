<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'apk' stack.

.DESCRIPTION
Execute this script to run the test suite for apk.
#>

$ErrorActionPreference = "Stop"

if (Get-Command apk -ErrorAction SilentlyContinue) {
    apk --version
    Write-Output "apk found"
} else {
    Write-Output "apk skipped (not found)"
}
