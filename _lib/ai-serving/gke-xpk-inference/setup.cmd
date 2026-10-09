@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the GKE XPK inference stack stack.
:: 
:: ## Usage
:: Execute this script to install and configure gke-xpk-inference on the local system.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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


set "CLUSTER_NAME=%XPK_CLUSTER_NAME%"
if "%CLUSTER_NAME%"=="" set "CLUSTER_NAME=ml-xpk-cluster"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

echo Setting up XPK Production Cluster Stack...

call gcloud auth print-access-token >nul 2>&1
if %errorlevel% neq 0 call gcloud auth login

echo Creating GKE cluster %CLUSTER_NAME% via xpk...
call "%~dp0\..\..\..\_lib\cloud-providers\gcp\gke-tpu-cluster\cli.cmd" create "%CLUSTER_NAME%"

echo Setup complete.
