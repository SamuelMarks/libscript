@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for iis on Windows.
:: Prepares and configures iis on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript iis installation on Windows.

set "THIS_FILE=%~f0"

echo Enabling IIS Web Server on Windows...
powershell -Command "Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart -WarningAction SilentlyContinue" >nul 2>&1
if errorlevel 1 (
    dism.exe /online /enable-feature /featurename:IIS-WebServerRole /all /norestart >nul 2>&1
)

echo IIS enabled successfully.
exit /b 0
