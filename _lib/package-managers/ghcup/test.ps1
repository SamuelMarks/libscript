<#
.SYNOPSIS
Test suite for the ghcup component.

.DESCRIPTION
Execute this script to perform a component-specific test.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command ghcup -ErrorAction SilentlyContinue) {
    & ghcup --version
} else {
    Write-Host "ghcup is not installed, skipping test."
}
