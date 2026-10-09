# ## Overview
# Automated backup utility for Open edX on Windows (PowerShell).
# Creates consolidated zip archives containing database dumps, media, and configurations.
#
# ## Usage
#   .\backup.ps1 create [-Out <archive_path>]
#   .\backup.ps1 list
#   .\backup.ps1 help

<#
.SYNOPSIS
    Automated backup utility for Open edX.
.DESCRIPTION
    Creates consolidated backup archives containing database dumps, media, and configurations,
    or lists existing backup archives.
#>

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter()]
    [string]$Out
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$LibscriptRootDir = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

$BackupDir = if ($env:OPENEDX_BACKUP_DIR) { $env:OPENEDX_BACKUP_DIR } else { Join-Path $InstallDir "backups" }

# ## Find-Python
# Discovers Python interpreter in virtual environment or PATH.
function Find-Python {
    $venvPy = Join-Path $InstallDir ".venv\Scripts\python.exe"
    if (Test-Path $venvPy) {
        return $venvPy
    }
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pyCmd) {
        return "python"
    }
    throw "Python interpreter not found in virtualenv or PATH."
}

# ## Show-Help
# Displays usage documentation.
function Show-Help {
    Write-Host "Open edX Backup Utility (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\backup.ps1 create [-Out <archive_path>]"
    Write-Host "  .\backup.ps1 list"
    Write-Host "  .\backup.ps1 help"
}

# ## Invoke-Backup
# Creates a backup archive using backup_helper.ps1.
function Invoke-Backup {
    param([string]$ArchivePath)
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    $helper = Join-Path $ScriptDir "backup_helper.ps1"
    & $helper backup $BackupDir $InstallDir $ArchivePath
}

# ## Get-Backups
# Lists existing backup zip files.
function Get-Backups {
    if (-not (Test-Path $BackupDir)) {
        Write-Host "No backups found."
        return
    }
    $files = Get-ChildItem -Path $BackupDir -Filter "*.zip" -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-Host "No backups found."
        return
    }
    foreach ($f in $files) {
        Write-Host $f.Name
    }
}

switch ($Command.ToLower()) {
    "create" { Invoke-Backup -ArchivePath $Out }
    "list"   { Get-Backups }
    "help"   { Show-Help }
    default  {
        Write-Error "Unknown backup command: $Command"
        Show-Help
        exit 1
    }
}
