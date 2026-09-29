@echo off
set "THIS_FILE=%~f0"
:: # install_linux.cmd
::
:: ## Overview
:: Target Linux installation orchestrator for Windows environments.
:: Dispatches Linux distribution installation workflows targeting raw disks or virtual disks.
::
:: ## Usage
:: Call install_linux.cmd <target_dev> [flavor] [target_dir]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 ^<target_dev^> [flavor] [target_dir]
echo.
echo Deploys a Linux base system to target storage from Windows.
echo.
echo Flavors:
echo   alpine    - Minimal Alpine Musl system (default)
echo   debian    - Debian standard system
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DEV=%~1"
set "FLAVOR=%~2"
set "TARGET_DIR=%~3"

if "%TARGET_DEV%"=="" (
    echo [ERROR] Target device or disk path is required. >&2
    exit /b 1
)
if "%FLAVOR%"=="" set "FLAVOR=alpine"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_target"

echo [INSTALL-LINUX] Initiating Linux (%FLAVOR%) installation on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%install_linux.sh" "%TARGET_DEV%" "%FLAVOR%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%install_linux.sh" "%TARGET_DEV%" "%FLAVOR%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
echo LibScript Linux %FLAVOR% installed > "%TARGET_DIR%\.libscript_installed.stamp"
echo [OK] Linux (%FLAVOR%) installation completed successfully.
exit /b 0
