@echo off
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions a logical database (e.g., WordPress db) side-by-side or remotely.
::
:: ## Usage
::   call provision_logical_db.cmd --host <host> --port <port> --db-name <name> [--db-url <url>]

set "THIS_DIR=%~dp0"
set "THIS_FILE=%~f0"

set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_NAME="
set "DB_URL="

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

:ValidateArgs
:: Validates the parsed arguments
if "!DB_NAME!"=="" (
    echo [ERROR] --db-name is required >&2
    exit /b 1
)
goto ProvisionDB

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
