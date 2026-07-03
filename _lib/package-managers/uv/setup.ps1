<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'uv' stack.

.DESCRIPTION
Execute this script to install and configure uv on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "Installing uv..."
  Invoke-RestMethod -Uri https://astral.sh/uv/install.ps1 | Invoke-Expression
}
