<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'mamba' stack.

.DESCRIPTION
Execute this script to install and configure mamba on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command mamba -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
