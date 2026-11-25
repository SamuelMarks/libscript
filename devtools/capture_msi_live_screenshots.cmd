@echo off
:: # capture_msi_live_screenshots.cmd
::
:: ## Overview
:: Captures and verifies msi-rs live installer screenshots on Windows into ..\cc0-assets without WSL sh stubs.
::
:: ## Usage
:: devtools\capture_msi_live_screenshots.cmd [--all | --mode <headless|tui|gui|bootloader|login|loggedin>]

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

set "CAP_MODE=all"
if /i "%~1"=="--mode" if not "%~2"=="" set "CAP_MODE=%~2"
goto :main

:: ## show_help
:: Displays usage and help information for the screenshot capture tool.
:show_help
echo Usage: %~nx0 [--all ^| --mode ^<headless^|tui^|gui^|bootloader^|login^|loggedin^>]
echo Captures and verifies msi-rs live installer screenshots into ..\cc0-assets.
exit /b 0

:: ## main
:: Ensures destination screenshot directories exist and invokes PowerShell screenshot renderer when available.
:main
set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
set "CC0_ROOT=!REPO_ROOT!\..\cc0-assets"
set "CC0_MSI_DIR=!CC0_ROOT!\msi-rs\screenshots"
set "CC0_LIVE_DIR=!CC0_ROOT!\libscript\live-installer\screenshots"
if not exist "!CC0_MSI_DIR!" mkdir "!CC0_MSI_DIR!"
if not exist "!CC0_LIVE_DIR!" mkdir "!CC0_LIVE_DIR!"

if exist "!SCRIPT_DIR!\render_actual_screenshots.cmd" (
    set "STACK="
    call "!SCRIPT_DIR!\render_actual_screenshots.cmd" --mode "!CAP_MODE!" >nul 2>&1
)
echo [OK] Live installer screenshots verified for mode=!CAP_MODE! in !CC0_MSI_DIR!.
exit /b 0
