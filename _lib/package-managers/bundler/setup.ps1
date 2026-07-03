<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'bundler' stack.

.DESCRIPTION
Execute this script to install and configure bundler on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command bundler -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
