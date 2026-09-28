@echo off
set "THIS_FILE=%~f0"
:: # create_desktop_shortcuts.cmd
::
:: ## Overview
:: Ensures Open edX desktop shortcuts exist with proper icons on user desktop and refreshes shell.
::
:: ## Usage
:: call "%~dp0create_desktop_shortcuts.cmd"

setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT_DIR%\create_desktop_shortcuts.ps1" %*
exit /b %ERRORLEVEL%
