@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the TPU VM vLLM AI serving stack stack.
:: 
:: ## Usage
:: Execute this script to deploy tpu-vm-vllm to the target environment.

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
echo #!/bin/sh
echo set -ex
echo if ! command -v docker ^> /dev/null 2^>^&1; then
echo   ~/_lib/orchestration/docker/setup.sh
echo fi
echo MODEL_NAME="%MODEL_NAME%"
echo IMAGE="us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"
echo sudo docker pull $IMAGE
echo sudo docker run -d --rm --name vllm-server --privileged --network host -v /dev:/dev $IMAGE --model "$MODEL_NAME" --tensor-parallel-size 1
) > "%SCRIPT_FILE%"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" "sh -s" < "%SCRIPT_FILE%"

echo Deploy complete.
