@echo off
:: # exports.cmd
::
:: ## Overview
:: Exports environment variables and location configurations for nginx on Windows.
::
:: ## Usage
:: call exports.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\.."
)

set "DIR=%SCRIPT_DIR%"

if exist "%LIBSCRIPT_ROOT_DIR%\_lib\_common\environ.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\environ.cmd"
)

exit /b 0
