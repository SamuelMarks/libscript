<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'xpk' stack.

.DESCRIPTION
Execute this script to install and configure xpk on the local system.
#>

$ErrorActionPreference = "Stop"

$XpkVersion = $env:XPK_VERSION
if ([string]::IsNullOrEmpty($XpkVersion)) {
    $XpkVersion = "latest"
}

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
    $Prefix = "$LibscriptRootDir\installed\xpk"
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\xpk.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Installing xpk into a virtual environment at $Prefix ..."
    
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python."
        exit 1
    }

    & python -m venv "$Prefix\venv"
    
    if ($XpkVersion -eq "latest") {
        & "$Prefix\venv\Scripts\pip.exe" install xpk
    } else {
        & "$Prefix\venv\Scripts\pip.exe" install "xpk==$XpkVersion"
    }

    $CmdContent = @"
@echo off
set "VENV_DIR=%~dp0..\venv"
"%VENV_DIR%\Scripts\xpk.exe" %*
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "xpk installed to $ExePath"
} else {
    Write-Host "xpk already installed at $ExePath"
}

if (-not ([string]::IsNullOrEmpty($env:GCP_PROJECT_ID))) {
    & $ExePath config set project $env:GCP_PROJECT_ID
}
if (-not ([string]::IsNullOrEmpty($env:GCP_ZONE))) {
    & $ExePath config set zone $env:GCP_ZONE
}
if (-not ([string]::IsNullOrEmpty($env:XPK_CLUSTER_NAME))) {
    & $ExePath config set cluster $env:XPK_CLUSTER_NAME
}
