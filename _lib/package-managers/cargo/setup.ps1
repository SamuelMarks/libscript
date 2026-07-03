<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'cargo' stack.

.DESCRIPTION
Execute this script to install and configure cargo on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command cargo -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Rust is installed on Windows."
}
