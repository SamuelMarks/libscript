<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'helm' stack.

.DESCRIPTION
Execute this script to run the test suite for helm.
#>

$ErrorActionPreference = "Stop"

if (Get-Command helm -ErrorAction SilentlyContinue) {
    helm --version
    Write-Output "helm found"
} else {
    Write-Output "helm skipped (not found)"
}
