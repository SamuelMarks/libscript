@echo off
:: # deploy.cmd
::
:: ## Overview
:: Idempotently submits the GKE XPK distributed training workload to the target TPU cluster on Windows.
::
:: ## Usage
:: payloads\ai\gke-xpk-training\deploy.cmd [--help]

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

if "%XPK_CLUSTER_NAME%"=="" set "XPK_CLUSTER_NAME=ml-xpk-cluster"
if "%WORKLOAD_NAME%"=="" set "WORKLOAD_NAME=ml-training-job"
if "%TRAIN_SCRIPT%"=="" set "TRAIN_SCRIPT=python train.py"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)
if "%DOCKER_IMAGE%"=="" (
    echo [ERROR] DOCKER_IMAGE must be specified.
    exit /b 1
)
if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

call xpk workload list --cluster "%XPK_CLUSTER_NAME%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" 2>nul | findstr /C:"%WORKLOAD_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Workload %WORKLOAD_NAME% already exists on cluster %XPK_CLUSTER_NAME%. Skipping duplicate submission.
    exit /b 0
)

echo [INFO] Deploying workload %WORKLOAD_NAME% to XPK cluster %XPK_CLUSTER_NAME%...
call xpk workload create --cluster "%XPK_CLUSTER_NAME%" --workload "%WORKLOAD_NAME%" --command "%TRAIN_SCRIPT%" --tpu-type "%TPU_ACCELERATOR_TYPE%" --docker-image "%DOCKER_IMAGE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%"

echo [INFO] Deploy complete.
exit /b 0

:: ## help
:: Prints usage help for deploy.cmd.
:help
echo Usage: deploy.cmd [--help]
exit /b 0
