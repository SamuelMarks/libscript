@echo off
:: # setup.cmd
::
:: ## Overview
:: Prepares the local environment and idempotently provisions the GKE XPK training cluster on Windows.
::
:: ## Usage
:: payloads\ai\gke-xpk-training\setup.cmd [--help]

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-cli\setup.cmd"
call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\python\setup.cmd"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\kubectl\setup.cmd"
call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\xpk\setup.cmd"

if "%XPK_CLUSTER_NAME%"=="" set "XPK_CLUSTER_NAME=ml-xpk-cluster"
if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

if "%GCP_PROJECT_ID%"=="" (
    echo [INFO] GCP_PROJECT_ID and GCP_ZONE not specified. Staging complete.
    exit /b 0
)
if "%GCP_ZONE%"=="" (
    echo [INFO] GCP_PROJECT_ID and GCP_ZONE not specified. Staging complete.
    exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-cli\cli.cmd" auth

call gcloud container clusters describe "%XPK_CLUSTER_NAME%" --zone="%GCP_ZONE%" --project="%GCP_PROJECT_ID%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] GKE cluster %XPK_CLUSTER_NAME% already exists in %GCP_ZONE%. Skipping creation.
) else (
    echo [INFO] Provisioning XPK cluster: %XPK_CLUSTER_NAME%...
    call xpk cluster create --cluster "%XPK_CLUSTER_NAME%" --tpu-type "%TPU_ACCELERATOR_TYPE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%"
)
echo [INFO] Setup complete.
exit /b 0

:: ## help
:: Prints usage help for setup.cmd.
:help
echo Usage: setup.cmd [--help]
exit /b 0
