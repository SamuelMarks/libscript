@echo off
:: # deploy.cmd
::
:: ## Overview
:: Idempotently deploys the vLLM TPU inference workload onto a GKE XPK cluster on Windows.
::
:: ## Usage
:: payloads\ai\gke-xpk-inference\deploy.cmd [--help]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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
if "%TPU_TENSOR_PARALLEL_SIZE%"=="" set "TPU_TENSOR_PARALLEL_SIZE=1"

call xpk workload list --cluster "%CLUSTER_NAME%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" 2>nul | findstr /C:"%WORKLOAD_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Workload %WORKLOAD_NAME% already exists on cluster %CLUSTER_NAME%. Skipping duplicate submission.
    exit /b 0
)

echo [INFO] Deploying workload %WORKLOAD_NAME% to XPK cluster %CLUSTER_NAME%...
call xpk workload create --cluster "%CLUSTER_NAME%" --workload "%WORKLOAD_NAME%" --command "python -m vllm.entrypoints.openai.api_server --model %MODEL_NAME% --tensor-parallel-size %TPU_TENSOR_PARALLEL_SIZE%" --tpu-type "%TPU_TYPE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" --docker-image "us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"

echo [INFO] Deploy complete.
exit /b 0

:: ## help
:: Prints usage help for deploy.cmd.
:help
echo Usage: deploy.cmd [--help]
exit /b 0
