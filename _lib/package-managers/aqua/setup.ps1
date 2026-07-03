<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'aqua' stack.

.DESCRIPTION
Execute this script to install and configure aqua on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command aqua -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
