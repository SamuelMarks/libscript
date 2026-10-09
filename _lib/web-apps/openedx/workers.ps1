# ## Overview
# Background worker and Celery beat scheduler management utility for Open edX on Windows (PowerShell).
# Manages lms-worker, cms-worker, and celery-beat lifecycle (start, stop, restart, status).
#
# ## Usage
#   .\workers.ps1 start
#   .\workers.ps1 stop
#   .\workers.ps1 restart
#   .\workers.ps1 status
#   .\workers.ps1 help

<#
.SYNOPSIS
    Worker and scheduler management CLI for Open edX.
.DESCRIPTION
    Starts, stops, restarts, and checks status of Celery workers and scheduler daemons.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$RunDir = Join-Path $InstallDir "run"
$LogDir = Join-Path $InstallDir "logs"
if (-not (Test-Path $RunDir)) { New-Item -ItemType Directory -Path $RunDir -Force | Out-Null }
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$PythonBin = Join-Path $InstallDir ".venv\Scripts\python.exe"
if (-not (Test-Path $PythonBin)) {
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    $PythonBin = if ($pyCmd) { "python" } else { "python.exe" }
}

$WorkersHelper = Join-Path $ScriptDir "workers_helper.ps1"

# ## Show-Help
# Displays worker management CLI command usage.
function Show-Help {
    Write-Host "Open edX Worker & Scheduler Management CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\workers.ps1 start"
    Write-Host "  .\workers.ps1 stop"
    Write-Host "  .\workers.ps1 restart"
    Write-Host "  .\workers.ps1 status"
    Write-Host "  .\workers.ps1 help"
}

# ## Invoke-Start
# Starts background worker daemons.
function Invoke-Start {
    Write-Host "[INFO] Starting Open edX background workers..."
    & $WorkersHelper start $RunDir $LogDir $PythonBin $InstallDir
}

# ## Invoke-Stop
# Stops background worker daemons.
function Invoke-Stop {
    Write-Host "[INFO] Stopping Open edX background workers..."
    & $WorkersHelper stop $RunDir
}

# ## Invoke-Restart
# Restarts background worker daemons.
function Invoke-Restart {
    Invoke-Stop
    Invoke-Start
}

# ## Invoke-Status
# Displays status of background worker daemons.
function Invoke-Status {
    Write-Host "======================================================"
    Write-Host "              Open edX Background Workers Status"
    Write-Host "======================================================"
    & $WorkersHelper status $RunDir
    Write-Host "======================================================"
}

switch ($Command.ToLower()) {
    "start"   { Invoke-Start }
    "stop"    { Invoke-Stop }
    "restart" { Invoke-Restart }
    "status"  { Invoke-Status }
    "help"    { Show-Help }
    default   {
        Write-Error "Unknown workers command: $Command"
        Show-Help
        exit 1
    }
}
