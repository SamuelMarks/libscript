@echo off
:: # live_linux.cmd
::
:: ## Overview
:: Synthesizes live-CD and live-USB bootable Linux environments (Alpine/Debian)
:: with overlayfs, live initramfs, and embedded msi-rs installer suite.
::
:: ## Usage
:: Execute this script to generate a live Linux image:
::   ./_lib/orchestration/distro/live_linux.cmd [distro_flavor] [output_path] [build_dir]

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
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 [distro_flavor] [output_path] [build_dir]
echo.
echo Builds bootable live Linux ISO images with msi-rs on Windows.
echo.
echo Flavors:
echo   alpine    - Minimal Alpine Musl live environment (default)
echo   debian    - Debian live system with squashfs
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "FLAVOR=%~1"
set "OUTPUT_PATH=%~2"
set "BUILD_DIR=%~3"

if "%FLAVOR%"=="" set "FLAVOR=alpine"
if "%OUTPUT_PATH%"=="" set "OUTPUT_PATH=%REPO_ROOT%\build\msi-linux-live.iso"
if "%BUILD_DIR%"=="" set "BUILD_DIR=%REPO_ROOT%\build\live-linux-%FLAVOR%"

echo [BUILD] Synthesizing live Linux (%FLAVOR%) image on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "!SCRIPT_DIR!live_linux.sh" "%FLAVOR%" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "!SCRIPT_DIR!live_linux.sh" "%FLAVOR%" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system. >&2
echo [ERROR] Please install WSL or Git Bash to generate Linux live media. >&2
exit /b 86
