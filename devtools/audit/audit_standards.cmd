@echo off
set "THIS_FILE=%~f0"
:: # audit_standards.cmd
::
:: ## Overview
:: Audits codebase and staged files for adherence to LibScript engineering standards:
:: - POSIX /bin/sh usage and canonical THIS_FILE preamble
:: - Windows batch script parity (.cmd / .bat)
:: - No evil eval usage
:: - Idempotency patterns
:: - 100% doc block coverage (## Overview and ## Usage)
:: 
:: ## Usage
:: Execute this script to audit files:
::   devtools\audit\audit_standards.cmd [--all | --staged]

setlocal EnableDelayedExpansion

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %~nx0 [--all ^| --staged]
echo Audits files for adherence to LibScript engineering standards.
echo.
echo Options:
echo   --all               Audit all tracked script files in repository.
echo   --staged            Audit git-staged files (default if no files given).
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes main functionality.
:main
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot audit standards on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%audit_standards.ps1" %*
exit /b %ERRORLEVEL%
