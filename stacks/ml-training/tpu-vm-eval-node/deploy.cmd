@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the TPU VM evaluation node for ML stack.
:: 
:: ## Usage
:: Execute this script to deploy tpu-vm-eval-node to the target environment.

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

if "%TPU_NAME%"=="" set "TPU_NAME=ml-eval-node"
if "%ML_SCRIPT%"=="" set "ML_SCRIPT=python train.py"

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
gcloud compute tpus tpu-vm scp --recurse "%~dp0..\..\..\_lib" "%TPU_NAME%:~/" --zone="%TPU_ZONE%" %PROJECT_FLAG%

echo Installing components on TPU VM...
gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "~/_lib/storage-layers/gcsfuse/setup.sh && ~/_lib/utilities/tmux/setup.sh && ~/_lib/logging/tensorboard/setup.sh"

set "SCRIPT_FILE=%TEMP%\ml_deploy.sh"

(
echo #!/bin/bash
echo set -ex
echo mkdir -p /mnt/ml_data
echo gcsfuse --implicit-dirs "%BUCKET_NAME%" /mnt/ml_data
echo ~/_lib/logging/tensorboard/cli.sh start /mnt/ml_data/logs 6006 ^|^| tensorboard --logdir=/mnt/ml_data/logs --port=6006 --host=0.0.0.0 ^&
) > "%SCRIPT_FILE%"

call "%~dp0\..\..\..\_lib\cloud-providers\gcp\tpu-vm\cli.cmd" ssh "%TPU_NAME%" "bash -s" < "%SCRIPT_FILE%"

echo Triggering detached training session and port-forwarding TensorBoard...
call "%~dp0\..\..\..\_lib\cloud-providers\gcp\tpu-vm\cli.cmd" ssh "%TPU_NAME%" --detached --forward-port 6006:localhost:6006 "cd /mnt/ml_data && %ML_SCRIPT%"

echo Deploy complete. TensorBoard is available at http://localhost:6006
echo To re-attach to the training session, run: tpu-vm ssh %TPU_NAME% "tmux attach"
