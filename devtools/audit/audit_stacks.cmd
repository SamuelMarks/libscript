@echo off
:: # audit_stacks.cmd
::
:: ## Overview
:: Performs an audit and validation of all defined application stacks.
:: 
:: ## Usage
:: Execute this script to check the integrity of stack definitions.

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
echo Performs an audit and validation of all defined application stacks.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes main functionality.
:main
:: ## main
:: Executes main functionality.
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot audit stacks on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%audit_stacks.ps1" %*
exit /b %ERRORLEVEL%
