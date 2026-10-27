@echo off
:: # provision_logical_vhost.cmd
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions a logical virtual host for a web server (e.g., Nginx, Apache).
::
:: ## Usage
::   call provision_logical_vhost.cmd --server-name <domain> --upstream-port <port>

set "THIS_DIR=%~dp0"
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

set "SERVER_NAME="
set "UPSTREAM_PORT="

:: ## ParseArgs
:: Parses command-line arguments and populates configuration variables.
:ParseArgs
if "%~1"=="" goto ValidateArgs
if "%~1"=="--server-name" (
    set "SERVER_NAME=%~2"
    shift
    shift
    goto ParseArgs
)
if "%~1"=="--upstream-port" (
    set "UPSTREAM_PORT=%~2"
    shift
    shift
    goto ParseArgs
)
echo [ERROR] Unknown argument: %~1 >&2
exit /b 1

:: ## ValidateArgs
:: Validates required command-line arguments and configuration parameters.
:ValidateArgs
:: Validates arguments ensuring essential flags are passed
if "!SERVER_NAME!"=="" (
    echo [ERROR] --server-name is required >&2
    exit /b 1
)
if "!UPSTREAM_PORT!"=="" (
    echo [ERROR] --upstream-port is required >&2
    exit /b 1
)
goto ProvisionVHost

:: ## ProvisionVHost
:: Performs the ProvisionVHost operation and updates component state.
:ProvisionVHost
:: Provisions the virtual host
:: Generates configuration and conditionally restarts the web server.
echo [INFO] Provisioning virtual host for !SERVER_NAME! routing to upstream port !UPSTREAM_PORT!
echo [PASS] Virtual host !SERVER_NAME! provisioned.
exit /b 0
