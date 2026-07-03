<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'fnm' stack.

.DESCRIPTION
Execute this script to install and configure fnm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command fnm -ErrorAction SilentlyContinue)) {
  Write-Host "Installing fnm..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://fnm.vercel.stacks/install")
}
