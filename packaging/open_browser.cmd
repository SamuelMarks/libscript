@echo off
:: # open_browser.cmd
::
:: ## Overview
:: Cross-platform browser launcher utility wrapper for Windows.
:: Launches browser natively in interactive Session 1 with dedicated profile.
::
:: ## Usage
:: call "%~dp0open_browser.cmd" [url]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT_DIR%\open_browser.ps1" %*
exit /b %ERRORLEVEL%
