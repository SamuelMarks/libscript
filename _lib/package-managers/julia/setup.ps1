<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'julia' stack.

.DESCRIPTION
Execute this script to install and configure julia on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command julia -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
