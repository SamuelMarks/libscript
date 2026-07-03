<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'npm' stack.

.DESCRIPTION
Execute this script to install and configure npm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
