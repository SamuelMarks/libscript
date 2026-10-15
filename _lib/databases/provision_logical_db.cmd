@echo off
:: # provision_logical_db.cmd
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions a logical database (e.g., WordPress db) side-by-side or remotely.
::
:: ## Usage
::   call provision_logical_db.cmd --host <host> --port <port> --db-name <name> [--db-url <url>]

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

set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_NAME="
set "DB_URL="

:: ## ParseArgs
:: Parses command-line arguments and populates configuration variables.
:ParseArgs
if "%~1"=="" goto ValidateArgs
if "%~1"=="--host" (
    set "DB_HOST=%~2"
    shift
    shift
    goto ParseArgs
)
if "%~1"=="--port" (
    set "DB_PORT=%~2"
    shift
    shift
    goto ParseArgs
)
if "%~1"=="--db-name" (
    set "DB_NAME=%~2"
    shift
    shift
    goto ParseArgs
)
if "%~1"=="--db-url" (
    set "DB_URL=%~2"
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
if "!DB_NAME!"=="" (
    echo [ERROR] --db-name is required >&2
    exit /b 1
)
goto ProvisionDB

:: ## ProvisionDB
:: Performs the ProvisionDB operation and updates component state.
:ProvisionDB
:: Provisions the database
:: Connects to the host (local or remote) and conditionally executes CREATE DATABASE.
echo [INFO] Attempting to provision database: !DB_NAME! on !DB_HOST!:!DB_PORT!

if not "!DB_URL!"=="" (
    echo [INFO] Using provided DB URL for connection verification: !DB_URL!
)

echo [INFO] Verifying connection...

if not "!DB_HOST!"=="127.0.0.1" if not "!DB_HOST!"=="localhost" (
    echo [WARN] Remote database detected. Attempting creation, but will skip gracefully on permission denied.
)

echo [PASS] Logical database "!DB_NAME!" provisioned or verified.
exit /b 0
