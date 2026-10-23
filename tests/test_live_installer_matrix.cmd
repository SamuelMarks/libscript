@echo off
:: # test_live_installer_matrix.cmd
::
:: ## Overview
:: Multi-platform Vagrant verification harness for the msi-rs live installer.
:: Executes end-to-end testing strictly inside isolated Vagrant virtual machines
:: across Linux, FreeBSD, SunOS (illumos), Windows, and macOS with 2-pass idempotency checks.
::
:: ## Usage
:: Execute this script to perform multi-platform Vagrant verification:
::   ./tests/test_live_installer_matrix.cmd [--all | --platform <linux|freebsd|sunos|windows|macos>]

setlocal EnableDelayedExpansion
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



if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [--all ^| --platform ^<name^>]
echo.
echo Runs multi-platform live installer verification strictly inside Vagrant VMs.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=%SCRIPT_DIR%\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SUMMARY_FILE=%REPO_ROOT%\tests_tmp\live_installer_matrix_summary.json"
if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"

echo [VAGRANT-MATRIX] Starting Vagrant Multi-Platform Verification on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%\test_live_installer_matrix.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%\test_live_installer_matrix.sh" %*
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] The test suite orchestrator requires a shell environment.
exit /b 1
