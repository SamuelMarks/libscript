# ## Overview
# Disaster recovery and restore utility for Open edX on Windows (PowerShell).
# Unpacks backup zip archives and restores configurations, users, and datastores.
#
# ## Usage
#   .estore.ps1 apply <archive_path> [-Yes]
#   .estore.ps1 help

<#
.SYNOPSIS
    Disaster recovery and restore utility for Open edX.
.DESCRIPTION
    Restores configurations, user accounts, and media from an Open edX backup archive.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$ArchivePath,

    [Parameter()]
    [switch]$Yes
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
# Displays restore utility command usage.
function Show-Help {
    Write-Host "Open edX Disaster Recovery & Restore Utility (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .estore.ps1 apply <archive_path> [-Yes]"
    Write-Host "  .estore.ps1 help"
}

# ## Invoke-Restore
# Applies a backup zip archive to the Open edX installation.
function Invoke-Restore {
    param([string]$Archive, [bool]$Force)
    if ([string]::IsNullOrEmpty($Archive)) {
        Write-Error "Archive path is required."
        exit 1
    }
    if (-not (Test-Path $Archive)) {
        Write-Error "Archive file does not exist: $Archive"
        exit 1
    }

    $helper = Join-Path $ScriptDir "backup_helper.ps1"
    $forceArg = if ($Force) { "1" } else { "0" }
    & $helper restore $Archive $InstallDir $forceArg
}

switch ($Command.ToLower()) {
    "apply"   { Invoke-Restore -Archive $ArchivePath -Force $Yes.IsPresent }
    "restore" { Invoke-Restore -Archive $ArchivePath -Force $Yes.IsPresent }
    "help"    { Show-Help }
    default   {
        Write-Error "Unknown restore command: $Command"
        Show-Help
        exit 1
    }
}
