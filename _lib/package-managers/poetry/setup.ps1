<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'poetry' stack.

.DESCRIPTION
Execute this script to install and configure poetry on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command poetry -ErrorAction SilentlyContinue)) {
  Write-Host "Installing poetry..."
  (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -
}
