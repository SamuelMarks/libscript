@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Provides a generic, cross-platform uninstallation mechanism for the celery stack on Windows.
:: 
:: ## Usage
:: Execute this script to perform generic removal steps for celery.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\.."
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\uninstall_generic.cmd" %*
