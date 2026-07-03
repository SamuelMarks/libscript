<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'vllm' stack.

.DESCRIPTION
Execute this script to install and configure vllm on the local system.
#>

$ErrorActionPreference = "Stop"

$VllmVersion = $env:VLLM_VERSION
if ([string]::IsNullOrEmpty($VllmVersion)) {
    $VllmVersion = "latest"
}

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
    $Prefix = "$LibscriptRootDir\installed\vllm"
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\vllm-serve.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Installing vLLM into a virtual environment at $Prefix ..."
    
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python."
        exit 1
    }

    & python -m venv "$Prefix\venv"
    
    if ($VllmVersion -eq "latest") {
        & "$Prefix\venv\Scripts\pip.exe" install vllm
    } else {
        & "$Prefix\venv\Scripts\pip.exe" install "vllm==$VllmVersion"
    }

    $CmdContent = @"
@echo off
setlocal
set "VENV_DIR=%~dp0..\venv"
set "MODEL=%~1"
if "%MODEL%"=="" set "MODEL=your-org/your-model-name"
set "TPS=%TPU_TENSOR_PARALLEL_SIZE%"
if "%TPS%"=="" set "TPS=1"

shift
set "REST_ARGS="
:loop
if "%~1"=="" goto run
set "REST_ARGS=%REST_ARGS% %1"
shift
goto loop

:run
"%VENV_DIR%\Scripts\python.exe" -m vllm.entrypoints.openai.api_server --model "%MODEL%" --tensor-parallel-size "%TPS%" %REST_ARGS%
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "vLLM wrapper installed to $ExePath"
} else {
    Write-Host "vLLM wrapper already installed at $ExePath"
}
