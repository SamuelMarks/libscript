@echo off
setlocal
if "%~1"=="--help" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)


set "TPU_NAME=%TPU_NAME%"
if "%TPU_NAME%"=="" set "TPU_NAME=ml-tpu-vm"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%TPU_ZONE%"=="" (
    echo [ERROR] TPU_ZONE must be explicitly specified.
    exit /b 1
)

echo Setting up TPU VM Prototyping Stack...

call gcloud auth print-access-token >nul 2>&1
if %errorlevel% neq 0 call gcloud auth login

echo Creating TPU VM %TPU_NAME%...
call "%~dp0\..\..\..\_lib\cloud-providers\gcp\tpu-vm\cli.cmd" create "%TPU_NAME%"

echo Setup complete.
