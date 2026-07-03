<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'pip' stack.

.DESCRIPTION
Execute this script to install and configure pip on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command pip -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Python is installed on Windows."
}
