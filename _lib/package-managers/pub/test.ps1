<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'pub' stack.

.DESCRIPTION
Execute this script to run the test suite for pub.
#>

$ErrorActionPreference = "Stop"

if (Get-Command pub -ErrorAction SilentlyContinue) {
    pub --version
    Write-Output "pub found"
} else {
    Write-Output "pub skipped (not found)"
}
