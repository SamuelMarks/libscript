@echo off
:: # preflight.cmd
::
:: ## Overview
:: Pre-flight checker to verify native cloud CLI (aws, gcloud, az) installations and authentication status on Windows.
::
:: ## Usage
:: call "%~dp0preflight.cmd" :libscript_check_preflight aws

goto :%1

:: ## libscript_check_preflight
:: Executes libscript_check_preflight functionality.
:libscript_check_preflight
set "provider=%~2"
if "%provider%"=="" (
    echo Error: Provider not specified for pre-flight check. >&2
    exit /b 1
)

if "%provider%"=="aws" (
    where aws >nul 2>nul
    if errorlevel 1 (
        echo Error: 'aws' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    aws sts get-caller-identity >nul 2>nul
    if errorlevel 1 (
        echo Error: AWS CLI is not authenticated. Please run 'aws configure'. >&2
        exit /b 1
    )
) else if "%provider%"=="gcp" (
    where gcloud >nul 2>nul
    if errorlevel 1 (
        echo Error: 'gcloud' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    gcloud auth print-access-token >nul 2>nul
    if errorlevel 1 (
        echo Error: GCP CLI is not authenticated. Please run 'gcloud auth login'. >&2
        exit /b 1
    )
) else if "%provider%"=="azure" (
    where az >nul 2>nul
    if errorlevel 1 (
        echo Error: 'az' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    az account show >nul 2>nul
    if errorlevel 1 (
        echo Error: Azure CLI is not authenticated. Please run 'az login'. >&2
        exit /b 1
    )
) else (
    echo Error: Unknown provider '%provider%' for pre-flight check. >&2
    exit /b 1
)

exit /b 0
