@echo off
:: # config.cmd
::
:: ## Overview
:: Declarative OS configuration driver supporting profiles, schema validation, and JSON export on Windows.
::
:: ## Usage
:: config.cmd os [--profile=<name>] [--export=<out.json>] [--validate=<file.json>]

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

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is required to execute config on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%config.ps1" %*
exit /b %ERRORLEVEL%
