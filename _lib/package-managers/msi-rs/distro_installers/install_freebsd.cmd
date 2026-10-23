@echo off
:: # install_freebsd.cmd
::
:: ## Overview
:: Target operating system installation pipeline for FreeBSD.
:: Unpacks base.txz and kernel.txz archives, configures /etc/rc.conf and /boot/loader.conf,
:: provisions ZFS datasets or UFS filesystems, and sets up EFI/BIOS bootloader code.
::
:: ## Usage
:: Execute this script to install FreeBSD to a target device:
::   ./_lib/package-managers/msi-rs/distro_installers/install_freebsd.cmd <target_dev> [target_dir]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 ^<target_dev^> [target_dir]
echo.
echo Deploys a FreeBSD base system to target storage from Windows.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=!SCRIPT_DIR!\..\..\..\.."
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
    wsl sh "!SCRIPT_DIR!\install_freebsd.sh" "%TARGET_DEV%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "!SCRIPT_DIR!\install_freebsd.sh" "%TARGET_DEV%" "%TARGET_DIR%"
    exit /b !errorlevel!
)

echo [ERROR] Native FreeBSD UFS/ZFS sysroot installation is unsupported on Win32 without WSL/sh. >&2
exit /b 86
