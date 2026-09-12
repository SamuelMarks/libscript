@echo off
:: # prelude.cmd
::
:: ## Overview
:: Common preamble and initialization logic shared across netctl batch scripts.
:: 
:: ## Usage
:: Call this script to initialize NETCTL_DIR on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined NETCTL_DIR (
    set "NETCTL_DIR=%SCRIPT_DIR%\.."
)

endlocal & set "NETCTL_DIR=%NETCTL_DIR%"
exit /b 0
