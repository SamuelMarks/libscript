<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'winget' stack.

.DESCRIPTION
Execute this script to install and configure winget on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..."
    Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile "$env:TEMP\winget.msixbundle"
    Add-AppxPackage "$env:TEMP\winget.msixbundle"
} else {
    Write-Host "winget is already installed."
}
