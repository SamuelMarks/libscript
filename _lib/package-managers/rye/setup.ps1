<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rye' stack.

.DESCRIPTION
Execute this script to install and configure rye on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command rye -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
