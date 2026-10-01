@echo off
set "THIS_FILE=%~f0"
:: # live_linux.cmd
::
:: ## Overview
:: Live Linux image synthesis orchestrator for Windows environments.
:: Directs building ISO and raw disk images for Linux live-CD/USB with msi-rs.
::
:: ## Usage
:: Call live_linux.cmd [distro_flavor] [output_path] [build_dir]

setlocal EnableDelayedExpansion

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
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
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
    wsl sh "%SCRIPT_DIR%live_linux.sh" "%FLAVOR%" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%live_linux.sh" "%FLAVOR%" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] Please install WSL or Git Bash to generate Linux live media.
exit /b 1
