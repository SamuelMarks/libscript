@echo off
:: # test_harvest_licenses.cmd
::
:: ## Overview
:: Automated unit and integration tests for universal dependency license harvesting on Windows.
:: Verifies license extraction from leaf packages and composite application stacks,
:: RTF and plain-text output validation, metadata manifest generation, and idempotency.
::
:: ## Usage
:: call tests\test_harvest_licenses.cmd

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
    sh "%SCRIPT_DIR%\test_harvest_licenses.sh" %*
    exit /b %ERRORLEVEL%
)

where bash.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    bash "%SCRIPT_DIR%\test_harvest_licenses.sh" %*
    exit /b %ERRORLEVEL%
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%\test_harvest_licenses.sh'" %*
exit /b %ERRORLEVEL%
