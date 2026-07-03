<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'go-pm' stack.

.DESCRIPTION
Execute this script to install and configure go-pm on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command go -ErrorAction SilentlyContinue)) {
  Write-Host "Please ensure Go is installed on Windows. Falling back to libscript toolchain setup..."
  & "$PSScriptRoot\..\..\_toolchain\go\setup.ps1"
}
