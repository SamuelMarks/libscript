@echo off
:: # deploy.cmd
::
:: ## Overview
:: Executes a Tier 4 AI training or inference workload on a provisioned GCP Cloud TPU VM on Windows.
:: Supports --detached, --forward-port, APP_DIR syncing, and HF_TOKEN forwarding.
::
:: ## Usage
:: payloads\ai\gcp-tpu-vm\deploy.cmd [--detached] [--forward-port <spec>] [--help]

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

set "EXTRA_SSH_ARGS="

:: ## parse_args
:: Parses CLI flags for detached execution and port forwarding.
:parse_args
if "%~1"=="" goto :run_deploy
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--detached" (
    set "EXTRA_SSH_ARGS=!EXTRA_SSH_ARGS! --detached"
    shift
    goto :parse_args
)
if "%~1"=="--forward-port" (
    set "EXTRA_SSH_ARGS=!EXTRA_SSH_ARGS! --forward-port %~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## run_deploy
:: Dispatches the workload command to the target TPU VM.
:run_deploy
if "%TPU_NAME%"=="" set "TPU_NAME=ml-tpu-vm"
if "%WORKLOAD_CMD%"=="" set "WORKLOAD_CMD=%ML_SCRIPT%"
if "%WORKLOAD_CMD%"=="" set "WORKLOAD_CMD=python3 train.py"
if "%APP_DIR%"=="" set "APP_DIR=%REPO_DIR%"

if not "!APP_DIR!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" scp "!APP_DIR!" "%TPU_NAME%:~/workspace"
    set "WORKLOAD_CMD=cd ~/workspace && !WORKLOAD_CMD!"
)
if not "%HF_TOKEN%"=="" (
    set "WORKLOAD_CMD=export HF_TOKEN='%HF_TOKEN%'; !WORKLOAD_CMD!"
)

echo [INFO] Dispatching Tier 4 AI workload to TPU VM %TPU_NAME%...
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-tpu-vm\cli.cmd" ssh "%TPU_NAME%" !EXTRA_SSH_ARGS! "!WORKLOAD_CMD!"
exit /b %errorlevel%

:: ## help
:: Prints command usage instructions.
:help
echo Usage: deploy.cmd [--detached] [--forward-port ^<spec^>] [--help]
exit /b 0
