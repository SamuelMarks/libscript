<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'jetstream' stack.

.DESCRIPTION
Execute this script to install and configure jetstream on the local system.
#>

$ErrorActionPreference = "Stop"

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
    $Prefix = "$LibscriptRootDir\installed\jetstream"
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\jetstream-serve.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Setting up JetStream wrapper at $Prefix ..."
    
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Host "Docker not found. Please install Docker."
        exit 1
    }

    $CmdContent = @"
@echo off
setlocal
set "MODEL=%~1"
if "%MODEL%"=="" set "MODEL=your-org/your-model-name"

set "MODEL_DIR=%MODEL_DIR%"
if "%MODEL_DIR%"=="" set "MODEL_DIR=%USERPROFILE%\.cache\models"
if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

set "JETSTREAM_IMAGE=%JETSTREAM_IMAGE%"
if "%JETSTREAM_IMAGE%"=="" set "JETSTREAM_IMAGE=us-docker.pkg.dev/cloud-tpu-images/inference/jetstream-pytorch-tpu:latest"

shift
set "REST_ARGS="
:loop
if "%~1"=="" goto run
set "REST_ARGS=%REST_ARGS% %1"
shift
goto loop

:run
echo Launching JetStream for %MODEL%...
docker run --rm -it --privileged --network host -v /dev:/dev -v "%MODEL_DIR%:/models" "%JETSTREAM_IMAGE%" --model_id "%MODEL%" --model_path "/models/%MODEL%" %REST_ARGS%
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "JetStream wrapper installed to $ExePath"
} else {
    Write-Host "JetStream wrapper already installed at $ExePath"
}
