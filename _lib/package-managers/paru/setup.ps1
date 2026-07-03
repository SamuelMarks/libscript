<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'paru' stack.

.DESCRIPTION
Execute this script to install and configure paru on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command paru -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
