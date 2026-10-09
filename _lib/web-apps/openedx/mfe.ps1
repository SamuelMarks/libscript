# ## Overview
# Micro-Frontend (MFE) build, configuration, and delivery pipeline for Open edX on Windows (PowerShell).
# Manages learning, authn, account, and course-authoring MFEs.
#
# ## Usage
#   .\mfe.ps1 build <mfe_name> [-Version <version>]
#   .\mfe.ps1 deploy <mfe_name> [-Dest <path>]
#   .\mfe.ps1 list
#   .\mfe.ps1 help

<#
.SYNOPSIS
    Micro-Frontend (MFE) pipeline for Open edX.
.DESCRIPTION
    Builds, configures, and deploys Open edX Micro-Frontend applications.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$MfeName,

    [Parameter()]
    [string]$Version = "master",

    [Parameter()]
    [string]$Dest
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

$MfeRootDir = Join-Path $InstallDir "mfes"
$MfeDistDir = Join-Path $InstallDir "mfe_dist"
if (-not (Test-Path $MfeRootDir)) { New-Item -ItemType Directory -Path $MfeRootDir -Force | Out-Null }
if (-not (Test-Path $MfeDistDir)) { New-Item -ItemType Directory -Path $MfeDistDir -Force | Out-Null }

$MfeHelper = Join-Path $ScriptDir "mfe_helper.ps1"

# ## Show-Help
# Displays MFE CLI command usage.
function Show-Help {
    Write-Host "Open edX Micro-Frontend (MFE) Pipeline CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\mfe.ps1 build <mfe_name> [-Version <version>]"
    Write-Host "  .\mfe.ps1 deploy <mfe_name> [-Dest <path>]"
    Write-Host "  .\mfe.ps1 list"
    Write-Host "  .\mfe.ps1 help"
}

# ## Invoke-MfeBuild
# Triggers building an Open edX MFE bundle.
function Invoke-MfeBuild {
    param([string]$Name, [string]$Ver)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Error "MFE name required."
        exit 1
    }
    Write-Host "[INFO] Building MFE '$Name'..."
    & $MfeHelper build $MfeRootDir $Name $Ver
}

# ## Invoke-MfeDeploy
# Deploys a compiled MFE bundle.
function Invoke-MfeDeploy {
    param([string]$Name, [string]$DestPath)
    if ([string]::IsNullOrEmpty($Name)) {
        Write-Error "MFE name required."
        exit 1
    }
    Write-Host "[INFO] Deploying MFE '$Name'..."
    & $MfeHelper deploy $MfeRootDir $MfeDistDir $Name $DestPath
}

# ## Invoke-MfeList
# Lists configured Micro-Frontends.
function Invoke-MfeList {
    Write-Host "============================================================"
    & $MfeHelper list $MfeRootDir
    Write-Host "============================================================"
}

switch ($Command.ToLower()) {
    "build"  { Invoke-MfeBuild -Name $MfeName -Ver $Version }
    "deploy" { Invoke-MfeDeploy -Name $MfeName -DestPath $Dest }
    "list"   { Invoke-MfeList }
    "help"   { Show-Help }
    default  {
        Write-Error "Unknown mfe command: $Command"
        Show-Help
        exit 1
    }
}
