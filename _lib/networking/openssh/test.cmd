@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies OpenSSH functionality on Windows.
::
:: ## Usage
:: Execute this script to test OpenSSH.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where ssh >nul 2>&1
if %errorlevel% equ 0 (
    ssh -V
    exit /b 0
)

echo [SKIP] OpenSSH not found on PATH.
exit /b 0
