@echo off
:: # test_msi_multi_license.cmd
::
:: ## Overview
:: Validates WiX Windows Installer (.msi) multi-license dialog sequence generation on Windows.
:: Asserts that each bundled component receives a dedicated license agreement dialog,
:: individual acceptance checkbox property, sequential UI routing, and unattended guard.
::
:: ## Usage
:: call tests\test_msi_multi_license.cmd

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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

where sh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sh "%SCRIPT_DIR%\test_msi_multi_license.sh" %*
    exit /b %ERRORLEVEL%
)

where bash.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    bash "%SCRIPT_DIR%\test_msi_multi_license.sh" %*
    exit /b %ERRORLEVEL%
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%\test_msi_multi_license.sh'" %*
exit /b %ERRORLEVEL%
