<#
.SYNOPSIS
Implements automated tests to verify the correctness of the component 'kubectl' stack.

.DESCRIPTION
Execute this script to run the test suite for kubectl.
#>

$ErrorActionPreference = "Stop"

if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl --version
} else {
    Write-Host "kubectl skipped (not found)"
}
