@echo off
:: # capture_browser_tabs.cmd
::
:: ## Overview
:: Automates launching Microsoft Edge with LMS and Studio tabs, toggling tab focus, and signaling screenshot capture.
::
:: ## Usage
:: call "%~dp0capture_browser_tabs.cmd" [-LmsUrl <url>] [-StudioUrl <url>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## run_capture
:: Invokes Edge browser automation PowerShell script.
:run_capture
set "PS_SCRIPT=%SCRIPT_DIR%\capture_browser_tabs.ps1"
if not exist "%PS_SCRIPT%" set "PS_SCRIPT=C:\libscript\capture_browser_tabs.ps1"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
exit /b %ERRORLEVEL%
