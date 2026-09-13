@echo off
rem ## Overview
rem Test suite for the iis component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%SystemRoot%\System32\inetsrv\appcmd.exe" (
    "%SystemRoot%\System32\inetsrv\appcmd.exe" list site
    exit /b 0
)

sc query w3svc >nul 2>&1
if %errorlevel% equ 0 (
    echo IIS W3SVC service verified.
    exit /b 0
)

powershell -Command "if ((Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -ErrorAction SilentlyContinue).State -eq 'Enabled') { exit 0 } else { exit 1 }"
