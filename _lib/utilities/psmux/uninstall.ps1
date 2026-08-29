# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles the removal and uninstallation process for the component 'psmux' stack.

.DESCRIPTION
Execute this script to remove psmux and its associated configurations from the system.
#>

$ErrorActionPreference = "Stop"

$InstallDir = "C:\Program Files\psmux"

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "psmux directory removed."
}

$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -match [regex]::Escape($InstallDir)) {
    $PathParts = $CurrentPath -split ';' | Where-Object { $_ -ne $InstallDir }
    $NewPath = $PathParts -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "Machine")
    Write-Host "Removed psmux from PATH."
}

Write-Host "psmux uninstalled."
