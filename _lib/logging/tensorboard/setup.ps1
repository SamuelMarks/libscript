<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'tensorboard' stack.

.DESCRIPTION
Execute this script to install and configure tensorboard on the local system.
#>

$ErrorActionPreference = "Stop"

$TensorboardVersion = $env:TENSORBOARD_VERSION
if ([string]::IsNullOrEmpty($TensorboardVersion)) {
    $TensorboardVersion = "latest"
}

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
    $Prefix = "$LibscriptRootDir\installed\tensorboard"
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\tensorboard.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Installing tensorboard into a virtual environment at $Prefix ..."
    
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python."
        exit 1
    }

    & python -m venv "$Prefix\venv"
    
    if ($TensorboardVersion -eq "latest") {
        & "$Prefix\venv\Scripts\pip.exe" install tensorboard
    } else {
        & "$Prefix\venv\Scripts\pip.exe" install "tensorboard==$TensorboardVersion"
    }

    $CmdContent = @"
@echo off
set "VENV_DIR=%~dp0..\venv"
"%VENV_DIR%\Scripts\tensorboard.exe" %*
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "tensorboard installed to $ExePath"
} else {
    Write-Host "tensorboard already installed at $ExePath"
}
