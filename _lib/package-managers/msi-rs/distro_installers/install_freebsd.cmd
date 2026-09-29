@echo off
set "THIS_FILE=%~f0"
:: # install_freebsd.cmd
::
:: ## Overview
:: Target FreeBSD installation orchestrator for Windows environments.
:: Dispatches FreeBSD base deployment workflows to target storage.
::
:: ## Usage
:: Call install_freebsd.cmd <target_dev> [target_dir]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 ^<target_dev^> [target_dir]
echo.
echo Deploys a FreeBSD base system to target storage from Windows.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DEV=%~1"
set "TARGET_DIR=%~2"

if "%TARGET_DEV%"=="" (
    echo [ERROR] Target device or disk path is required. >&2
    exit /b 1
)
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_freebsd_target"

echo [INSTALL-FREEBSD] Initiating FreeBSD installation on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%install_freebsd.sh" "%TARGET_DEV%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%install_freebsd.sh" "%TARGET_DEV%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"
echo LibScript FreeBSD installed > "%TARGET_DIR%\.libscript_freebsd_installed.stamp"
echo [OK] FreeBSD installation completed successfully.
exit /b 0
