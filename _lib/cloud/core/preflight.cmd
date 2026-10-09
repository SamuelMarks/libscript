@echo off
:: # preflight.cmd
::
:: ## Overview
:: Pre-flight checker to verify native cloud CLI (aws, gcloud, az) installations and authentication status on Windows.
::
:: ## Usage
:: call "%~dp0preflight.cmd" :libscript_check_preflight aws
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

goto :%1

:: ## libscript_check_preflight
:: Executes libscript_check_preflight functionality.
:libscript_check_preflight
set "provider=%~2"
if "%provider%"=="" (
    echo Error: Provider not specified for pre-flight check. >&2
    exit /b 1
)

if "%provider%"=="aws" (
    where aws >nul 2>nul
    if errorlevel 1 (
        echo Error: 'aws' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    aws sts get-caller-identity >nul 2>nul
    if errorlevel 1 (
        echo Error: AWS CLI is not authenticated. Please run 'aws configure'. >&2
        exit /b 1
    )
) else if "%provider%"=="gcp" (
    where gcloud >nul 2>nul
    if errorlevel 1 (
        echo Error: 'gcloud' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    gcloud auth print-access-token >nul 2>nul
    if errorlevel 1 (
        echo Error: GCP CLI is not authenticated. Please run 'gcloud auth login'. >&2
        exit /b 1
    )
) else if "%provider%"=="azure" (
    where az >nul 2>nul
    if errorlevel 1 (
        echo Error: 'az' CLI is not installed or not in PATH. >&2
        exit /b 1
    )
    az account show >nul 2>nul
    if errorlevel 1 (
        echo Error: Azure CLI is not authenticated. Please run 'az login'. >&2
        exit /b 1
    )
) else (
    echo Error: Unknown provider '%provider%' for pre-flight check. >&2
    exit /b 1
)

exit /b 0
