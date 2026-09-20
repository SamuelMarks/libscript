@echo off
set "THIS_FILE=%~f0"
:: # backup_helper.cmd
::
:: ## Overview
:: Backup and disaster recovery helper utility for Open edX on Windows.
:: Creates consolidated compressed archives and applies restoration snapshots.
::
:: ## Usage
:: Call stacks\cms\openedx\backup_helper.cmd backup <backup_dir> <install_dir> [out_path]
:: Call stacks\cms\openedx\backup_helper.cmd restore <archive> <install_dir> [force]

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 backup ^<backup_dir^> ^<install_dir^> [out_path]
echo        %~nx0 restore ^<archive^> ^<install_dir^> [force]
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to backup_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%backup_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%backup_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute backup helper. >&2
exit /b 1
