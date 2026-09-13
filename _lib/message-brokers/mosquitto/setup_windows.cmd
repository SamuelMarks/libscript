@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where mosquitto >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing Mosquitto via winget...
winget install --id EclipseFoundation.Mosquitto --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 exit /b 0

echo Mosquitto configured.
exit /b 0
