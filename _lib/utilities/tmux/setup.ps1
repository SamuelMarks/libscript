<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'tmux' stack.

.DESCRIPTION
Execute this script to install and configure tmux on the local system.
#>

$ErrorActionPreference = "Stop"

Write-Host "Installing psmux as the native Windows alternative for tmux..."
$PsmuxSetup = Join-Path $PSScriptRoot "..\psmux\setup.ps1"
if (Test-Path $PsmuxSetup) {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PsmuxSetup
} else {
    Write-Host "Warning: psmux setup script not found at $PsmuxSetup"
}

