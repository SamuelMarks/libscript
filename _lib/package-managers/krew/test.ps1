<#
.SYNOPSIS
Test suite for the krew component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command kubectl-krew -ErrorAction SilentlyContinue) {
    try {
        & kubectl-krew --version
    } catch {
        try {
            & kubectl-krew version
        } catch {}
    }
} else {
    Write-Host "kubectl-krew is not installed, skipping test."
}
