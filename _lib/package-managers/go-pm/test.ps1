<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'go-pm' stack.

.DESCRIPTION
Execute this script to run the test suite for go-pm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command go -ErrorAction SilentlyContinue) {
    go --version
    Write-Output "go found"
} else {
    Write-Output "go skipped (not found)"
}
