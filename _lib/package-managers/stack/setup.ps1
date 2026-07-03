<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'stack' stack.

.DESCRIPTION
Execute this script to install and configure stack on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command stack -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
