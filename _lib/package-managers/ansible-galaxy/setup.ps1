<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'ansible-galaxy' stack.

.DESCRIPTION
Execute this script to install and configure ansible-galaxy on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command ansible-galaxy -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
