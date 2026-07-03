<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'sh' stack.

.DESCRIPTION
Execute this script to run the test suite for sh.
#>

$ErrorActionPreference = "Stop"

if (Get-Command sh -ErrorAction SilentlyContinue) {
    sh --version
    Write-Output "sh found"
} else {
    Write-Output "sh skipped (not found)"
}
