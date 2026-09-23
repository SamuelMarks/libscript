@echo off
:: # deploy-remote.cmd
::
:: ## Overview
:: Orchestrates idempotent deployment of multiple apps to a remote host.
:: Safe over-the-network payload deployment and live service reloading.
:: 
:: ## Usage
:: Syntax: deploy-remote.cmd <user@host> [--app <path>@<domain>]... [--shared-db <engine>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<user@host^> [--app ^<path^>@^<domain^>]... [--shared-db ^<engine^>]
    echo Orchestrates remote application deployment.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<user@host^> [--app ^<path^>@^<domain^>]... [--shared-db ^<engine^>]
    echo Orchestrates remote application deployment.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\deploy_remote.cmd" %*
exit /b %ERRORLEVEL%
