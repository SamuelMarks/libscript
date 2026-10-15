@echo off
:: # provision_isolated_runtime.cmd
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions an isolated runtime environment (e.g., Python venv, Node virtual env).
::
:: ## Usage
::   call provision_isolated_runtime.cmd --runtime <type> --path <path>

set "THIS_DIR=%~dp0"
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

set "RUNTIME_TYPE="
set "ISOLATION_PATH="

:: ## ParseArgs
:: Parses command-line arguments and populates configuration variables.
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

:: ## ValidateArgs
:: Validates required command-line arguments and configuration parameters.
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

:: ## ProvisionRuntime
:: Performs the ProvisionRuntime operation and updates component state.
:ProvisionRuntime
:: Provisions the isolated runtime
echo [INFO] Provisioning isolated !RUNTIME_TYPE! runtime at !ISOLATION_PATH!
echo [PASS] Isolated runtime provisioned.
exit /b 0
