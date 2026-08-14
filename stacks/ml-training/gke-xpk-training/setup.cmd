@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the GKE XPK machine learning training stack stack.
:: 
:: ## Usage
:: Execute this script to install and configure gke-xpk-training on the local system.

setlocal enabledelayedexpansion

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

call "%~dp0..\..\..\_lib\cloud-providers\gcp\cli\setup.cmd"
call "%~dp0..\..\..\_lib\toolchains\python\setup.cmd"
call "%~dp0..\..\..\_lib\orchestration\kubernetes\kubectl\setup.cmd"
call "%~dp0..\..\..\_lib\toolchains\xpk\setup.cmd"

if "%XPK_CLUSTER_NAME%"=="" set "XPK_CLUSTER_NAME=ml-xpk-cluster"
if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

echo Authenticating with GCP...
call "%~dp0..\..\..\_lib\cloud-providers\gcp\cli\cli.cmd" auth

echo Provisioning XPK cluster: %XPK_CLUSTER_NAME%...
xpk cluster create --cluster "%XPK_CLUSTER_NAME%" --tpu-type "%TPU_ACCELERATOR_TYPE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%"

echo Setup complete.
exit /b 0

:: ## help
:: Executes help functionality.
:help
echo Usage: setup.cmd
exit /b 0