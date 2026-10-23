@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the TPU VM evaluation node for ML stack.
:: 
:: ## Usage
:: Execute this script to deploy tpu-vm-eval-node to the target environment.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if "%TPU_NAME%"=="" set "TPU_NAME=ml-eval-node"
if "%ML_SCRIPT%"=="" set "ML_SCRIPT=%TRAIN_CMD%"
if "%ML_SCRIPT%"=="" set "ML_SCRIPT=%TRAIN_SCRIPT%"
if "%ML_SCRIPT%"=="" set "ML_SCRIPT=python train.py"
if "%BUCKET_NAME%"=="" set "BUCKET_NAME=%GCS_BUCKET%"
if /i "!BUCKET_NAME:~0,5!"=="gs://" set "BUCKET_NAME=!BUCKET_NAME:~5!"
if "%TPU_DATA_DISK_SIZE%"=="" set "TPU_DATA_DISK_SIZE=%DISK_SIZE_GB%"
if "%TPU_DATA_DISK_SIZE%"=="" set "TPU_DATA_DISK_SIZE=200"
if "%DISK_NAME%"=="" set "DISK_NAME=%TPU_NAME%-data"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%TPU_ZONE%"=="" (
    echo [ERROR] TPU_ZONE must be explicitly specified.
    exit /b 1
)

if "%BUCKET_NAME%"=="" (
    echo [ERROR] BUCKET_NAME must be set for GCS FUSE.
    exit /b 1
)

set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

echo Deploying execution loop to %TPU_NAME%...

echo Syncing libscript components to TPU VM...
gcloud compute tpus tpu-vm scp --recurse "!LIBSCRIPT_ROOT_DIR!\_lib" "%TPU_NAME%:~/" --zone="%TPU_ZONE%" %PROJECT_FLAG%

echo Installing components on TPU VM...
gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "~/_lib/storage-layers/gcsfuse/setup.sh && ~/_lib/utilities/tmux/setup.sh && ~/_lib/logging/tensorboard/setup.sh"

set "SCRIPT_FILE=%TEMP%\ml_deploy.sh"

(
echo #!/bin/sh
echo set -ex
echo mkdir -p /mnt/ml_data
echo gcsfuse --implicit-dirs "%BUCKET_NAME%" /mnt/ml_data
echo ~/_lib/logging/tensorboard/cli.sh start /mnt/ml_data/logs 6006 ^|^| tensorboard --logdir=/mnt/ml_data/logs --port=6006 --host=0.0.0.0 ^&
) > "%SCRIPT_FILE%"

call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" "sh -s" < "%SCRIPT_FILE%"

echo Triggering detached training session and port-forwarding TensorBoard...
call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" --detached --forward-port 6006:localhost:6006 "cd /mnt/ml_data && %ML_SCRIPT%"

echo Deploy complete. TensorBoard is available at http://localhost:6006
echo To re-attach to the training session, run: tpu-vm ssh %TPU_NAME% "tmux attach"
