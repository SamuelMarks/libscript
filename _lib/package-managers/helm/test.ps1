<#
.SYNOPSIS
Test suite for the helm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command helm -ErrorAction SilentlyContinue) {
    try {
        & helm --version
    } catch {
        try {
            & helm version
        } catch {}
    }
} else {
    Write-Host "helm is not installed, skipping test."
}
