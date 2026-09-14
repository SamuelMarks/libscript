@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for conan on Windows.
:: Prepares and configures conan on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript conan installation on Windows.

set "THIS_FILE=%~f0"

where conan >nul 2>&1
if %errorlevel% equ 0 (
    echo conan is already installed.
    exit /b 0
)

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing conan via pip...
    pip install conan --quiet
    if not errorlevel 1 exit /b 0
)

where winget >nul 2>&1
if not errorlevel 1 (
    echo Installing conan via winget...
    winget install --id conan.conan --silent --accept-package-agreements --accept-source-agreements
    if not errorlevel 1 exit /b 0
)

echo Failed to install conan.
exit /b 1
