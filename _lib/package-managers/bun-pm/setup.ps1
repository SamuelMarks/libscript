<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'bun-pm' stack.

.DESCRIPTION
Execute this script to install and configure bun-pm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command bun -ErrorAction SilentlyContinue)) {
  Write-Host "Installing bun..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://bun.sh/install.ps1")
}
