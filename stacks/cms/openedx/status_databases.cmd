@echo off
:: # status_databases.cmd
::
:: ## Overview
:: Wrapper script to detect existing databases and set MSI installer properties via standard exit codes.
:: This script wraps libscript status calls to interface with CustomActions cleanly.
::
:: ## Usage
:: call status_databases.cmd <component>
::
:: ## Parameters
:: %1 - Component name (e.g., databases/mysql)

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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

if "%~1"=="" (
    echo [ERROR] Missing component argument. >&2
    exit /b 1
)
set "COMPONENT=%~1"

call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" status "%COMPONENT%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    exit /b 0
) else (
    exit /b 1
)