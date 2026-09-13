@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo winget is already installed.
    exit /b 0
)

echo Installing winget via PowerShell AppX bootstrap...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe" >nul 2>&1

where winget >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo winget verified.
exit /b 0
