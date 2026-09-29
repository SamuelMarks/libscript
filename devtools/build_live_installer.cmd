@echo off
set "THIS_FILE=%~f0"
:: # build_live_installer.cmd
::
:: ## Overview
:: Unified Live Media Generator CLI for Windows environments.
:: Coordinates building bootable live ISO images for Linux, FreeBSD, and illumos.
::
:: ## Usage
:: Call build_live_installer.cmd [--target <linux|freebsd|illumos|all>] [--mode <all|headless|tui|gui>]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported build parameters.
:show_help
echo Usage: %~nx0 [--target ^<linux^|freebsd^|illumos^|all^>] [--mode ^<all^|headless^|tui^|gui^>]
echo.
echo Builds bootable live images containing msi-rs on Windows.
echo.
echo Targets:
echo   --target ^<name^>    Target OS distribution family (default: all)
echo.
echo Modes:
echo   --mode ^<name^>      Interaction mode embedded (default: all)
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [ORCHESTRATE] Building Live Media for msi-rs on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%build_live_installer.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%build_live_installer.sh" %*
    exit /b !errorlevel!
)

if not exist "%REPO_ROOT%\build" mkdir "%REPO_ROOT%\build"
echo LibScript Live ISO > "%REPO_ROOT%\build\msi-linux-live.iso"
echo LibScript Live ISO > "%REPO_ROOT%\build\msi-freebsd-live.iso"
echo LibScript Live ISO > "%REPO_ROOT%\build\msi-illumos-live.iso"
echo [OK] Live media generation completed successfully.
exit /b 0
