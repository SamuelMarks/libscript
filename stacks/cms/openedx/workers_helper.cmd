@echo off
set "THIS_FILE=%~f0"
:: # workers_helper.cmd
::
:: ## Overview
:: Background worker process manager helper for Open edX on Windows.
:: Manages daemon lifecycle, status monitoring, and graceful termination of workers.
::
:: ## Usage
:: Call stacks\cms\openedx\workers_helper.cmd start <run_dir> <log_dir> <py_bin> <install_dir>
:: Call stacks\cms\openedx\workers_helper.cmd stop <run_dir>
:: Call stacks\cms\openedx\workers_helper.cmd status <run_dir>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 start ^<run_dir^> ^<log_dir^> ^<py_bin^> ^<install_dir^>
echo        %~nx0 stop ^<run_dir^>
echo        %~nx0 status ^<run_dir^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to workers_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%workers_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%workers_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute workers helper. >&2
exit /b 1
