@echo off
:: # deploy.cmd
::
:: ## Overview
:: Executes a Tier 4 CUDA model-serving or training workload on a provisioned GCP GPU VM on Windows.
::
:: ## Usage
:: payloads\ai\gcp-gpu-vm\deploy.cmd [--help]

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

if "%GPU_NAME%"=="" set "GPU_NAME=ml-gpu-vm"
if "%WORKLOAD_CMD%"=="" set "WORKLOAD_CMD=python3 -m vllm.entrypoints.openai.api_server --port 8000"

echo [INFO] Dispatching Tier 4 AI workload to GPU VM %GPU_NAME%...
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud-providers\gcp-gpu-vm\cli.cmd" ssh "%GPU_NAME%" "%WORKLOAD_CMD%"
exit /b %errorlevel%

:: ## help
:: Prints command usage instructions.
:help
echo Usage: deploy.cmd [--help]
exit /b 0
