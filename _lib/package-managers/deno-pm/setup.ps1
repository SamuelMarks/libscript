<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'deno-pm' stack.

.DESCRIPTION
Execute this script to install and configure deno-pm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command deno -ErrorAction SilentlyContinue)) {
  Write-Host "Installing deno..."
  Invoke-Expression (Invoke-RestMethod -Uri "https://deno.land/install.ps1")
}
