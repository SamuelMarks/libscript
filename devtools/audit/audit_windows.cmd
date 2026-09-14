@echo off
set "THIS_FILE=%~f0"
:: # audit_windows.cmd
::
:: ## Overview
:: Audits all LibScript components on the Windows 11 Vagrant VM.
:: 
:: ## Usage
:: Execute this script to audit components on Windows.

setlocal EnableDelayedExpansion

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %~nx0
echo Audits all LibScript components on the Windows 11 Vagrant VM.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes main functionality.
:main
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%~dp0..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot audit windows components.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%audit_windows.ps1" %*
exit /b %ERRORLEVEL%
