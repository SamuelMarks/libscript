<#
.SYNOPSIS
Test suite for the hatch component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command hatch -ErrorAction SilentlyContinue) {
    try {
        & hatch --version
    } catch {
        try {
            & hatch version
        } catch {}
    }
} else {
    Write-Host "hatch is not installed, skipping test."
}
