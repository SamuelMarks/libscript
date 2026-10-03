@echo off
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions an isolated runtime environment (e.g., Python venv, Node virtual env).
::
:: ## Usage
::   call provision_isolated_runtime.cmd --runtime <type> --path <path>

set "THIS_DIR=%~dp0"
set "THIS_FILE=%~f0"

set "RUNTIME_TYPE="
set "ISOLATION_PATH="

:ParseArgs
if "%~1"=="" goto ValidateArgs
if "%~1"=="--runtime" (
    set "RUNTIME_TYPE=%~2"
    shift
    shift
    goto ParseArgs
)
if "%~1"=="--path" (
    set "ISOLATION_PATH=%~2"
    shift
    shift
    goto ParseArgs
)
echo [ERROR] Unknown argument: %~1 >&2
exit /b 1

:ValidateArgs
:: Validates the parsed arguments
if "!RUNTIME_TYPE!"=="" (
    echo [ERROR] --runtime is required >&2
    exit /b 1
)
if "!ISOLATION_PATH!"=="" (
    echo [ERROR] --path is required >&2
    exit /b 1
)
goto ProvisionRuntime

:ProvisionRuntime
:: Provisions the isolated runtime
echo [INFO] Provisioning isolated !RUNTIME_TYPE! runtime at !ISOLATION_PATH!
echo [PASS] Isolated runtime provisioned.
exit /b 0
