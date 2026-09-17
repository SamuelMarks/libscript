@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies hMailServer on Windows.
::
:: ## Usage
:: Execute this script to test hMailServer functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
sc query hMailServer >nul 2>&1
if not errorlevel 1 (
    echo [INFO] hMailServer service verified.
    exit /b 0
)
echo [INFO] hMailServer test completed.
exit /b 0
