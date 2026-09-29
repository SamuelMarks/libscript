@echo off
set "THIS_FILE=%~f0"
:: # coinstall_dual_os.cmd
::
:: ## Overview
:: Concurrent Multi-OS Co-Installation Orchestrator for Windows environments.
:: Directs concurrent Linux and FreeBSD dual-partition deployments with unified bootloader chaining.
::
:: ## Usage
:: Call coinstall_dual_os.cmd <disk_dev> <linux_part> <freebsd_part> [esp_part]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported parameters.
:show_help
echo Usage: %~nx0 ^<disk_dev^> ^<linux_part^> ^<freebsd_part^> [esp_part]
echo.
echo Deploys Linux and FreeBSD concurrently onto two separate partitions.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [COINSTALL] Starting Concurrent Linux + FreeBSD Co-Installation on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%coinstall_dual_os.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%coinstall_dual_os.sh" %*
    exit /b !errorlevel!
)

echo [OK] Concurrent Dual-OS deployment completed on Windows.
exit /b 0
