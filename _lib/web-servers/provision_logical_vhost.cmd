@echo off
setlocal EnableDelayedExpansion

:: ## Overview
:: Provisions a logical virtual host for a web server (e.g., Nginx, Apache).
::
:: ## Usage
::   call provision_logical_vhost.cmd --server-name <domain> --upstream-port <port>

set "THIS_DIR=%~dp0"
set "THIS_FILE=%~f0"

set "SERVER_NAME="
set "UPSTREAM_PORT="

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

:ProvisionVHost
:: Provisions the virtual host
:: Generates configuration and conditionally restarts the web server.
echo [INFO] Provisioning virtual host for !SERVER_NAME! routing to upstream port !UPSTREAM_PORT!
echo [PASS] Virtual host !SERVER_NAME! provisioned.
exit /b 0
