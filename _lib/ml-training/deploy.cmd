@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the TPU VM evaluation node for ML stack on Windows.
:: Supports APP_DIR/REPO_DIR syncing, libscript.json/pyproject.toml dependency installation,
:: optional BUCKET_NAME FUSE mounting, and safe environment secret forwarding.
:: 
:: ## Usage
:: Execute this script to deploy tpu-vm-eval-node to the target environment.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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
if "%APP_DIR%"=="" set "APP_DIR=%REPO_DIR%"
if "!APP_DIR!"=="" (
    if exist ".\libscript.json" set "APP_DIR=%CD%"
    if exist ".\pyproject.toml" set "APP_DIR=%CD%"
    if exist ".\requirements.txt" set "APP_DIR=%CD%"
)

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%TPU_ZONE%"=="" (
    echo [ERROR] TPU_ZONE must be explicitly specified.
    exit /b 1
)

set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

echo Deploying execution loop to %TPU_NAME%...

echo Syncing libscript components to TPU VM...
gcloud compute tpus tpu-vm scp --recurse "!LIBSCRIPT_ROOT_DIR!\_lib" "%TPU_NAME%:~/" --zone="%TPU_ZONE%" %PROJECT_FLAG%

if not "!APP_DIR!"=="" (
    if exist "!APP_DIR!" (
        echo Syncing application repository ^(!APP_DIR!^) to ~/workspace on TPU VM...
        gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "mkdir -p ~/workspace"
        gcloud compute tpus tpu-vm scp --recurse "!APP_DIR!" "%TPU_NAME%:~/workspace" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    )
)

set "ENV_SECRET_FILE=%TEMP%\ml_secrets_%RANDOM%.env"
type nul > "!ENV_SECRET_FILE!"
if not "%HF_TOKEN%"=="" echo export HF_TOKEN="%HF_TOKEN%">> "!ENV_SECRET_FILE!"
if not "%WANDB_API_KEY%"=="" echo export WANDB_API_KEY="%WANDB_API_KEY%">> "!ENV_SECRET_FILE!"
if not "%KERAS_BACKEND%"=="" echo export KERAS_BACKEND="%KERAS_BACKEND%">> "!ENV_SECRET_FILE!"
if not "%JAX_PLATFORMS%"=="" echo export JAX_PLATFORMS="%JAX_PLATFORMS%">> "!ENV_SECRET_FILE!"
if not "%MODEL_NAME%"=="" echo export MODEL_NAME="%MODEL_NAME%">> "!ENV_SECRET_FILE!"
if not "%DATASET_NAME%"=="" echo export DATASET_NAME="%DATASET_NAME%">> "!ENV_SECRET_FILE!"
if not "%DUCKDB_PATH%"=="" echo export DUCKDB_PATH="%DUCKDB_PATH%">> "!ENV_SECRET_FILE!"
if not "%DUCKDB_TABLE%"=="" echo export DUCKDB_TABLE="%DUCKDB_TABLE%">> "!ENV_SECRET_FILE!"
gcloud compute tpus tpu-vm scp "!ENV_SECRET_FILE!" "%TPU_NAME%:~/.env.ml_secrets" --zone="%TPU_ZONE%" %PROJECT_FLAG%
del /f /q "!ENV_SECRET_FILE!" >nul 2>&1

echo Installing components on TPU VM...
gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "~/_lib/storage-layers/gcsfuse/setup.sh && ~/_lib/utilities/tmux/setup.sh && ~/_lib/logging/tensorboard/setup.sh"

set "SCRIPT_FILE=%TEMP%\ml_deploy.sh"

(
echo #!/bin/sh
echo set -ex
echo if [ -n "%BUCKET_NAME%" ]; then
echo   mkdir -p /mnt/ml_data
echo   gcsfuse --implicit-dirs "%BUCKET_NAME%" /mnt/ml_data ^|^| true
echo   WORK_DATA_DIR="/mnt/ml_data"
echo else
echo   mkdir -p "$HOME/workspace/data"
echo   WORK_DATA_DIR="$HOME/workspace/data"
echo fi
echo if [ -f "$HOME/workspace/libscript.json" ] ^&^& [ -f "$HOME/libscript/libscript.sh" ]; then
echo   "$HOME/libscript/libscript.sh" install-deps "$HOME/workspace/libscript.json" ^|^| true
echo fi
echo if [ -f "$HOME/workspace/pyproject.toml" ] ^|^| [ -f "$HOME/workspace/requirements.txt" ]; then
echo   cd "$HOME/workspace" ^&^& pip install -e . ^|^| true
echo fi
echo mkdir -p "${WORK_DATA_DIR}/logs"
echo ~/_lib/logging/tensorboard/cli.sh start "${WORK_DATA_DIR}/logs" 6006 ^|^| tensorboard --logdir="${WORK_DATA_DIR}/logs" --port=6006 --host=0.0.0.0 ^&
) > "%SCRIPT_FILE%"

call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" "sh -s" < "%SCRIPT_FILE%"

set "REMOTE_RUN_DIR=/mnt/ml_data"
if "%BUCKET_NAME%"=="" set "REMOTE_RUN_DIR=~/workspace"
if not "!APP_DIR!"=="" set "REMOTE_RUN_DIR=~/workspace"

echo Triggering detached training session and port-forwarding TensorBoard...
call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" --detached --forward-port 6006:localhost:6006 "if [ -f ~/.env.ml_secrets ]; then . ~/.env.ml_secrets; fi && cd !REMOTE_RUN_DIR! && %ML_SCRIPT%"

echo Deploy complete. TensorBoard is available at http://localhost:6006
echo To re-attach to the training session, run: tpu-vm ssh %TPU_NAME% "tmux attach"
