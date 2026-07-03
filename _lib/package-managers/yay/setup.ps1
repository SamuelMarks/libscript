<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'yay' stack.

.DESCRIPTION
Execute this script to install and configure yay on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command yay -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
