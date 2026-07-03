<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rvm' stack.

.DESCRIPTION
Execute this script to install and configure rvm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command rvm -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Node.js is installed on Windows."
}
