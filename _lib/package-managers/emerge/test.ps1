<#
.SYNOPSIS
Test suite for the emerge component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command emerge -ErrorAction SilentlyContinue) {
    & emerge --version
} else {
    Write-Host "emerge is not installed, skipping test."
}
