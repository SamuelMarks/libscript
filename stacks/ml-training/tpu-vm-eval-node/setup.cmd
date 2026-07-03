@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the TPU VM evaluation node for ML stack.
:: 
:: ## Usage
:: Execute this script to install and configure tpu-vm-eval-node on the local system.

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
if "%TPU_NAME%"=="" set "TPU_NAME=ml-eval-node"

set "TPU_DATA_DISK_SIZE=%TPU_DATA_DISK_SIZE%"
if "%TPU_DATA_DISK_SIZE%"=="" set "TPU_DATA_DISK_SIZE=200"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%TPU_ZONE%"=="" (
    echo [ERROR] TPU_ZONE must be explicitly specified.
    exit /b 1
)

echo Setting up Comprehensive ML Training Stack on %TPU_NAME%...

call gcloud auth print-access-token >nul 2>&1
if %errorlevel% neq 0 call gcloud auth login

echo Provisioning TPU VM with %TPU_DATA_DISK_SIZE% GB persistent disk...
call "%~dp0\..\..\..\_lib\cloud-providers\gcp\tpu-vm\cli.cmd" create "%TPU_NAME%"

echo Setup complete.
