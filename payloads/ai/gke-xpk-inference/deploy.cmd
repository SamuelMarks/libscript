@echo off
:: # deploy.cmd
::
:: ## Overview
:: Idempotently deploys a parameterized TPU inference workload onto a GKE XPK cluster on Windows.
:: Supports custom WORKLOAD_CMD/SERVE_CMD, DOCKER_IMAGE, NUM_SLICES, TPU_SCHEDULING_TYPE, and HF_TOKEN.
::
:: ## Usage
:: payloads\ai\gke-xpk-inference\deploy.cmd [--command <cmd>] [--docker-image <img>] [--num-slices <n>] [--spot] [--env <K=V>] [--help]

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

set "EXTRA_ENV_FLAGS="

:: ## parse_args
:: Parses command-line flags for GKE XPK workload submission.
:parse_args
if "%~1"=="" goto :run_deploy
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--command" (
    set "WORKLOAD_CMD=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--docker-image" (
    set "DOCKER_IMAGE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--num-slices" (
    set "NUM_SLICES=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--spot" (
    set "TPU_SCHEDULING_TYPE=spot"
    shift
    goto :parse_args
)
if "%~1"=="--on-demand" (
    set "TPU_SCHEDULING_TYPE=on-demand"
    shift
    goto :parse_args
)
if "%~1"=="--env" (
    set "EXTRA_ENV_FLAGS=!EXTRA_ENV_FLAGS! --env %~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## run_deploy
:: Validates configuration and submits the workload via xpk.
:run_deploy
set "CLUSTER_NAME=%XPK_CLUSTER_NAME%"
if "!CLUSTER_NAME!"=="" set "CLUSTER_NAME=ml-xpk-cluster"
if "!WORKLOAD_CMD!"=="" set "WORKLOAD_CMD=%SERVE_CMD%"
if "!TPU_TENSOR_PARALLEL_SIZE!"=="" set "TPU_TENSOR_PARALLEL_SIZE=1"

if "!WORKLOAD_CMD!"=="" (
    if "%MODEL_NAME%"=="" (
        echo [ERROR] MODEL_NAME or WORKLOAD_CMD must be explicitly specified.
        exit /b 1
    )
    if "%MODEL_NAME%"=="your-org/your-model-name" (
        echo [ERROR] MODEL_NAME or WORKLOAD_CMD must be explicitly specified.
        exit /b 1
    )
    set "WORKLOAD_CMD=python -m vllm.entrypoints.openai.api_server --model %MODEL_NAME% --tensor-parallel-size !TPU_TENSOR_PARALLEL_SIZE!"
)

if "!DOCKER_IMAGE!"=="" set "DOCKER_IMAGE=us-docker.pkg.dev/cloud-tpu-images/inference/vllm-tpu:latest"
if "!WORKLOAD_NAME!"=="" set "WORKLOAD_NAME=ml-serve"
if "!NUM_SLICES!"=="" set "NUM_SLICES=%TPU_SLICE_COUNT%"
if "!NUM_SLICES!"=="" set "NUM_SLICES=1"
if "!TPU_ACCELERATOR_TYPE!"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

call xpk workload list --cluster "!CLUSTER_NAME!" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" 2>nul | findstr /C:"!WORKLOAD_NAME!" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Workload !WORKLOAD_NAME! already exists on cluster !CLUSTER_NAME!. Skipping duplicate submission.
    exit /b 0
)

set "EXTRA_XPK_FLAGS=--num-slices=!NUM_SLICES!"
if /i "!TPU_SCHEDULING_TYPE!"=="spot" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --spot"
if /i "!TPU_SCHEDULING_TYPE!"=="on-demand" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --on-demand"
if not "%HF_TOKEN%"=="" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --env HF_TOKEN=%HF_TOKEN%"
if not "!EXTRA_ENV_FLAGS!"=="" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS!!EXTRA_ENV_FLAGS!"

echo [INFO] Deploying workload !WORKLOAD_NAME! to XPK cluster !CLUSTER_NAME!...
call xpk workload create --cluster "!CLUSTER_NAME!" --workload "!WORKLOAD_NAME!" --command "!WORKLOAD_CMD!" --tpu-type "!TPU_ACCELERATOR_TYPE!" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" --docker-image "!DOCKER_IMAGE!" !EXTRA_XPK_FLAGS!

echo [INFO] Deploy complete.
exit /b 0

:: ## help
:: Prints usage help for deploy.cmd.
:help
echo Usage: deploy.cmd [--command ^<cmd^>] [--docker-image ^<img^>] [--num-slices ^<n^>] [--spot^|--on-demand] [--env ^<K=V^>] [--help]
exit /b 0
