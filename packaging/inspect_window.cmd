@echo off
:: # inspect_window.cmd
::
:: ## Overview
:: Diagnostic utility to inspect UI automation element hierarchy and button properties on Windows.
::
:: ## Usage
:: call "%~dp0inspect_window.cmd"

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## run_inspect
:: Invokes UIAutomation inspection PowerShell script.
:run_inspect
set "PS_SCRIPT=%SCRIPT_DIR%\inspect_window.ps1"
if not exist "%PS_SCRIPT%" set "PS_SCRIPT=C:\libscript\inspect_window.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
exit /b %ERRORLEVEL%
