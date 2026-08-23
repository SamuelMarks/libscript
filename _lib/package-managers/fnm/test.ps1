<#
.SYNOPSIS
Test suite for the fnm component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command fnm -ErrorAction SilentlyContinue) {
    & fnm --version
} else {
    Write-Host "fnm is not installed, skipping test."
}
