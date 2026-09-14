@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for pdm on Windows.
:: Prepares and configures pdm on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript pdm installation on Windows.

set "THIS_FILE=%~f0"

where pdm >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing pdm via pip...
    pip install pdm --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install pdm.
exit /b 1
