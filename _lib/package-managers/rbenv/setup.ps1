<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rbenv' stack.

.DESCRIPTION
Execute this script to install and configure rbenv on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command rbenv -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
