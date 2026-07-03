<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'gem' stack.

.DESCRIPTION
Execute this script to install and configure gem on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command gem -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Ruby is installed on Windows."
}
