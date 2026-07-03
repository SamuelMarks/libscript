<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'python-server' stack.

.DESCRIPTION
Execute this script to install and configure python-server on the local system.
#>

$ErrorActionPreference = "Stop"

Get-ChildItem "$PSScriptRoot\..\python\setup.cmd" | ForEach-Object { & $_.FullName }

if (Test-Path "$env:PYTHON_SERVER_DEST\requirements.txt") {
    Write-Host "[INFO] Installing Python dependencies..."
    pip install -r "$env:PYTHON_SERVER_DEST\requirements.txt"
}
