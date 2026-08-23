<#
.SYNOPSIS
Test suite for the gem component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command gem -ErrorAction SilentlyContinue) {
    & gem --version
} else {
    Write-Host "gem is not installed, skipping test."
}
