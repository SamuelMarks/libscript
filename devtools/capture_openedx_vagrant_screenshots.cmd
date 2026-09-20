@echo off
set "THIS_FILE=%~f0"
:: # capture_openedx_vagrant_screenshots.cmd
::
:: ## Overview
:: Automates launching Open edX Windows Installer (.msi) wizard inside Vagrant Windows 11,
:: stepping through every enumeration (Simple Mode and Advanced Mode flows),
:: capturing pixel-perfect screenshots of every wizard step, the desktop icons,
:: and the browser validation tabs directly from the live QEMU display framebuffer.
::
:: ## Usage
:: Call devtools\capture_openedx_vagrant_screenshots.cmd [--help]

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :parse_args

:: ## show_help
:: Displays usage and help information for the screenshot capture tool.
:show_help
echo Usage: %~nx0 [--help]
echo.
echo Automates capturing pixel-perfect screenshots of the Open edX MSI installer
echo running inside the Vagrant Windows 11 guest VM.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message and exit.
exit /b 0

:: ## parse_args
:: Parses command-line arguments.
:parse_args
goto :main

:: ## main
:: Executes primary orchestration routine.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%capture_openedx_vagrant_screenshots.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%capture_openedx_vagrant_screenshots.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to run screenshot automation. >&2
exit /b 1
