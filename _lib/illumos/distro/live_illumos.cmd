@echo off
set "THIS_FILE=%~f0"
:: # live_illumos.cmd
::
:: ## Overview
:: illumos live-CD/USB image synthesis orchestrator for Windows environments.
:: Directs building bootable illumos live media with embedded msi-rs installer suite.
::
:: ## Usage
:: Call live_illumos.cmd [output_path] [build_dir]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 [output_path] [build_dir]
echo.
echo Builds bootable live illumos ISO images with msi-rs on Windows.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "OUTPUT_PATH=%~1"
set "BUILD_DIR=%~2"

if "%OUTPUT_PATH%"=="" set "OUTPUT_PATH=%REPO_ROOT%\build\msi-illumos-live.iso"
if "%BUILD_DIR%"=="" set "BUILD_DIR=%REPO_ROOT%\build\live-illumos"

echo [BUILD] Synthesizing live illumos image on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%live_illumos.sh" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%live_illumos.sh" "%OUTPUT_PATH%" "%BUILD_DIR%"
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] Please install WSL or Git Bash to generate illumos live media.
exit /b 1
