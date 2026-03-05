@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot test IIS.
    exit /b 1
)

echo [TEST] Testing IIS configuration...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module WebAdministration; if (Get-Command Get-WebSite -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% EQU 0 (
    echo [PASS] IIS cmdlets available.
    exit /b 0
) else (
    echo [FAIL] IIS cmdlets not available.
    exit /b 1
)
