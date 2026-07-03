<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'nimble' stack.

.DESCRIPTION
Execute this script to install and configure nimble on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command nimble -ErrorAction SilentlyContinue)) {
  Write-Host "Installing nimble..."
  Write-Host "Please install Nim for Windows via nimble-lang.org installers or winget install Nim.Nim"
  exit 1
}
