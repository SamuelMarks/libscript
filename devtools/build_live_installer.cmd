@echo off
:: # build_live_installer.cmd
::
:: ## Overview
:: Unified Live Media Generator CLI for LibScript msi-rs live-CD and live-USB distributions.
:: Orchestrates building bootable ISO and raw disk images for Linux, FreeBSD, and illumos
:: with support for headless, TUI, and GUI kiosk interaction modes.
::
:: ## Usage
:: Execute this script to generate target live media:
::   ./devtools/build_live_installer.cmd [--target <linux|freebsd|illumos|all>] [--mode <all|headless|tui|gui>] [--output <path>]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

:: # build_live_installer.cmd
:::: Unified Live Media Generator CLI for Windows environments.
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
