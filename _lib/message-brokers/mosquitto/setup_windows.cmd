@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for mosquitto on Windows.
:: Prepares and configures mosquitto on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript mosquitto installation on Windows.

set "THIS_FILE=%~f0"

where mosquitto >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing Mosquitto via winget...
winget install --id EclipseFoundation.Mosquitto --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 exit /b 0

echo Mosquitto configured.
exit /b 0
