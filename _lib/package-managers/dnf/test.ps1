<#
.SYNOPSIS
Test suite for the dnf component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command dnf -ErrorAction SilentlyContinue) {
    & dnf --version
} else {
    Write-Host "dnf is not installed, skipping test."
}
