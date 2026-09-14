@echo off
:: # inject_markers.cmd
::
:: ## Overview
:: Injects specific markers or tags into documentation files.
:: 
:: ## Usage
:: Execute this script to apply structural markers to docs.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Executes show_help functionality.
:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Injects specific markers or tags into documentation files.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes main functionality.
:main
:: ## main
:: Executes main functionality.
:: Injects <!-- BEGIN_VARS --> and <!-- BEGIN_PLATFORMS --> markers into
:: README.md files. Windows equivalent of inject_markers.sh

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot inject markers on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%inject_markers.ps1" %*
exit /b %ERRORLEVEL%
