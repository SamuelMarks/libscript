@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the GKE XPK inference stack stack.
:: 
:: ## Usage
:: Execute this script to deploy gke-xpk-inference to the target environment.

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

set "MODEL_NAME=%MODEL_NAME%"
if "%MODEL_NAME%"=="" set "MODEL_NAME=your-org/your-model-name"
if "%MODEL_NAME%"=="your-org/your-model-name" (
    echo [ERROR] MODEL_NAME must be explicitly specified ^(cannot be empty or the placeholder^).
    exit /b 1
)

set "WORKLOAD_NAME=%WORKLOAD_NAME%"
if "%WORKLOAD_NAME%"=="" set "WORKLOAD_NAME=ml-serve"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

set "TPU_TYPE=%TPU_ACCELERATOR_TYPE%"
if "%TPU_TYPE%"=="" set "TPU_TYPE=v4-8"

echo Deploying workload %WORKLOAD_NAME% to XPK cluster %CLUSTER_NAME%...

call xpk workload create --cluster "%CLUSTER_NAME%" --workload "%WORKLOAD_NAME%" --command "python -m vllm.entrypoints.openai.api_server --model %MODEL_NAME% --tensor-parallel-size 1" --tpu-type "%TPU_TYPE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" --docker-image "us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"

echo Deploy complete.
