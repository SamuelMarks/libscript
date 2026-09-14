@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for gitlab on Windows.
:: Prepares and configures gitlab on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript gitlab installation on Windows.

set "THIS_FILE=%~f0"

where glab >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where gitlab-runner >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing GLab CLI via winget...
winget install --id GLab.GLab --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 exit /b 0

echo GitLab client wrapper configured.
exit /b 0
