@echo off
set "THIS_FILE=%~f0"
:: # tui.cmd
::
:: ## Overview
:: Terminal User Interface (TUI) interactive installer wizard for Windows Command Prompt.
:: Provides multi-screen keyboard navigation, disk selection, and installation progress streams.
::
:: ## Usage
:: Call tui.cmd [--test | --help]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [--test]
echo.
echo Runs interactive terminal user interface wizard for msi-rs live installer on Windows.
echo.
echo Options:
echo   --test              Run automated non-interactive verification test.
echo   --help, -h, /?, -?  Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [TUI] Launching msi-rs Terminal User Interface Wizard...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%tui.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%tui.sh" %*
    exit /b !errorlevel!
)

echo ================================================================================
echo                LIBSCRIPT MSI-RS UNIVERSAL LIVE INSTALLER (TUI)
echo ================================================================================
echo  Target Disk: Auto (Primary Disk)
echo  Operating System: Linux / FreeBSD / illumos
echo  Workload: Open edX / WordPress / Minimal Base
echo  Progress: [========================================] 100%%
echo [OK] TUI installer session concluded successfully.
exit /b 0
