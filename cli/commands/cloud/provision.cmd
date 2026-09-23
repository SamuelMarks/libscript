@echo off
:: # provision.cmd
::
:: ## Overview
:: Provisions cloud infrastructure and registers synthesized system images on Windows.
:: Validates profiles, ensures required artifacts exist, and delegates orchestration.
:: 
:: ## Usage
:: Call `provision.cmd [--profile=<file>] [--image=<path>] [--provider=aws|gcp|azure|proxmox|hetzner]`

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
    echo Usage: %~nx0 [--profile=^<file^>] [--image=^<path^>] [--provider=^<name^>]
    echo Provisions cloud infrastructure and registers synthesized system images.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [--profile=^<file^>] [--image=^<path^>] [--provider=^<name^>]
    echo Provisions cloud infrastructure and registers synthesized system images.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\deploy_cloud.cmd" %*
exit /b %ERRORLEVEL%
