@echo off
:: ## Overview
:: Windows setup script for Exim / local SMTP relay.

::
:: ## Usage
:: Call this script to trigger setup for exim on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"

if "%ACTION%"=="install" (
    echo [INFO] Exim is POSIX-specific. Routing to hMailServer for native Windows SMTP relay...
    call "%~dp0\..\hmailserver\setup.cmd" install
    exit /b 0
) else if "%ACTION%"=="test" (
    call "%~dp0\..\hmailserver\test.cmd"
    exit /b %ERRORLEVEL%
)

exit /b 0
