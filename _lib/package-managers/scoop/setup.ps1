<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'scoop' stack.

.DESCRIPTION
Execute this script to install and configure scoop on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
} else {
    Write-Host "scoop is already installed."
}
