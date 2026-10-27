@echo off
:: # coinstall_dual_os.cmd
::
:: ## Overview
:: Concurrent Multi-OS Co-Installation Orchestrator for Linux and FreeBSD.
:: Deploys Linux base and FreeBSD base concurrently onto two separate target partitions
:: of the same storage device, configures a shared EFI System Partition (ESP), and synthesizes
:: a unified dual-boot GRUB bootloader menu with automatic FreeBSD chainloading.
::
:: ## Usage
:: Execute this script with target device and partition paths:
::   ./_lib/package-managers/msi-rs/distro_installers/coinstall_dual_os.cmd <disk_dev> <linux_part> <freebsd_part> [esp_part]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found



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
set "REPO_ROOT=!SCRIPT_DIR!\..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [COINSTALL] Starting Concurrent Linux + FreeBSD Co-Installation on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "!SCRIPT_DIR!\coinstall_dual_os.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "!SCRIPT_DIR!\coinstall_dual_os.sh" %*
    exit /b !errorlevel!
)

echo [ERROR] Concurrent Dual-OS Linux/FreeBSD partitioning is unsupported on native Win32 without WSL/sh. >&2
exit /b 86
