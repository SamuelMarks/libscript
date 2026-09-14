@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for pipx on Windows.
:: Prepares and configures pipx on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript pipx installation on Windows.

set "THIS_FILE=%~f0"

where pipx >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing pipx via pip...
    pip install pipx --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install pipx.
exit /b 1
