@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the TPU VM vLLM AI serving stack stack.
:: 
:: ## Usage
:: Execute this script to deploy tpu-vm-vllm to the target environment.

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

set "MODEL_NAME=%MODEL_NAME%"
if "%MODEL_NAME%"=="" set "MODEL_NAME=your-org/your-model-name"
if "%MODEL_NAME%"=="your-org/your-model-name" (
    echo [ERROR] MODEL_NAME must be explicitly specified ^(cannot be empty or the placeholder^).
    exit /b 1
)

echo Deploying %MODEL_NAME% to TPU VM %TPU_NAME%...

set "SCRIPT_FILE=%TEMP%\deploy_tpu.sh"

(
echo #!/bin/bash
echo set -ex
echo if ! command -v docker ^> /dev/null 2^>^&1; then
echo   sudo apt-get update
echo   sudo apt-get install -y docker.io
echo   sudo usermod -aG docker $USER
echo fi
echo MODEL_NAME="%MODEL_NAME%"
echo IMAGE="us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"
echo sudo docker pull $IMAGE
echo sudo docker run -d --rm --name vllm-server --privileged --network host -v /dev:/dev $IMAGE --model "$MODEL_NAME" --tensor-parallel-size 1
) > "%SCRIPT_FILE%"

call "%~dp0\..\..\..\_lib\cloud-providers\gcp\tpu-vm\cli.cmd" ssh "%TPU_NAME%" "bash -s" < "%SCRIPT_FILE%"

echo Deploy complete.
