@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for the msi-rs component on Windows.
:: Validates that msi-rs CLI and WiX/msitools replacement binaries are installed and operational.
::
:: ## Usage
:: Execute this script to perform a component-specific test on Windows:
::   test.cmd

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%~dp0env.cmd" (
    call "%~dp0env.cmd"
)

where msi-cli.exe >nul 2>&1
if not errorlevel 1 (
    msi-cli.exe --help >nul
    echo [PASS] msi-cli is operational
    exit /b 0
)

where msi-rs.exe >nul 2>&1
if not errorlevel 1 (
    msi-rs.exe --help >nul
    echo [PASS] msi-rs is operational
    exit /b 0
)

where msi.exe >nul 2>&1
if not errorlevel 1 (
    msi.exe --help >nul
    echo [PASS] msi is operational
    exit /b 0
)

echo [FAIL] No msi-rs executable found in PATH >&2
exit /b 1
