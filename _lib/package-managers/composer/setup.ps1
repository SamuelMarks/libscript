<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'composer' stack.

.DESCRIPTION
Execute this script to install and configure composer on the local system.
#>

$ErrorActionPreference = "Stop"

if (-Not (Get-Command composer -ErrorAction SilentlyContinue)) {
  & "$PSScriptRoot\..\..\`_toolchain\composer\setup.ps1"
}
