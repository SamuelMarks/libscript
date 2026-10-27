@echo off
:: # deploy.cmd
::
:: ## Overview
:: Idempotently submits the GKE XPK distributed training workload to the target TPU cluster on Windows.
:: Supports --docker-image, --command, --tpu-type, --num-slices, --spot, and HF_TOKEN injection.
::
:: ## Usage
:: payloads\ai\gke-xpk-training\deploy.cmd [--command <cmd>] [--docker-image <img>] [--tpu-type <type>] [--num-slices <n>] [--spot] [--help]

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
:: Parses CLI flags for multi-slice XPK training submission.
:parse_args
if "%~1"=="" goto :run_deploy
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--command" (
    set "TRAIN_SCRIPT=%~2"
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
if "%~1"=="--tpu-type" (
    set "TPU_ACCELERATOR_TYPE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--num-slices" (
    set "TPU_SLICE_COUNT=%~2"
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
:: Validates configuration and submits the training workload to XPK.
:run_deploy
set "CLUSTER_NAME=%XPK_CLUSTER_NAME%"
if "!CLUSTER_NAME!"=="" set "CLUSTER_NAME=ml-xpk-cluster"
if "!WORKLOAD_NAME!"=="" set "WORKLOAD_NAME=ml-training-job"
if "!TRAIN_SCRIPT!"=="" set "TRAIN_SCRIPT=%ML_SCRIPT%"
if "!TRAIN_SCRIPT!"=="" set "TRAIN_SCRIPT=%TRAIN_CMD%"
if "!TRAIN_SCRIPT!"=="" set "TRAIN_SCRIPT=python train.py"
if "!TPU_SLICE_COUNT!"=="" set "TPU_SLICE_COUNT=%NUM_SLICES%"
if "!TPU_SLICE_COUNT!"=="" set "TPU_SLICE_COUNT=1"
if "!TPU_ACCELERATOR_TYPE!"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified for XPK workload.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified for XPK workload.
    exit /b 1
)
if "!DOCKER_IMAGE!"=="" (
    echo [ERROR] DOCKER_IMAGE must be specified.
    exit /b 1
)

call xpk workload list --cluster "!CLUSTER_NAME!" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" 2>nul | findstr /C:"!WORKLOAD_NAME!" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Workload !WORKLOAD_NAME! already exists on cluster !CLUSTER_NAME!. Skipping duplicate submission.
    exit /b 0
)

set "EXTRA_XPK_FLAGS=--num-slices=!TPU_SLICE_COUNT!"
if /i "!TPU_SCHEDULING_TYPE!"=="spot" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --spot"
if /i "!TPU_SCHEDULING_TYPE!"=="on-demand" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --on-demand"
if not "%HF_TOKEN%"=="" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --env HF_TOKEN=%HF_TOKEN%"
if not "!EXTRA_ENV_FLAGS!"=="" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS!!EXTRA_ENV_FLAGS!"

echo [INFO] Deploying workload !WORKLOAD_NAME! to XPK cluster !CLUSTER_NAME!...
call xpk workload create --cluster "!CLUSTER_NAME!" --workload "!WORKLOAD_NAME!" --command "!TRAIN_SCRIPT!" --tpu-type "!TPU_ACCELERATOR_TYPE!" --docker-image "!DOCKER_IMAGE!" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%" !EXTRA_XPK_FLAGS!

echo [INFO] Deploy complete.
exit /b 0

:: ## help
:: Prints usage help for deploy.cmd.
:help
echo Usage: deploy.cmd [--command ^<cmd^>] [--docker-image ^<img^>] [--tpu-type ^<type^>] [--num-slices ^<n^>] [--spot] [--help]
exit /b 0
