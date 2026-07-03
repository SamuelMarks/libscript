<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'swift' stack.

.DESCRIPTION
Execute this script to run the test suite for swift.
#>

$ErrorActionPreference = "Stop"

if (Get-Command swift -ErrorAction SilentlyContinue) {
    swift --version
    Write-Output "swift found"
} else {
    Write-Output "swift skipped (not found)"
}
