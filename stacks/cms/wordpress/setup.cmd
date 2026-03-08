@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Fallback to running PowerShell for Windows provisioning
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot configure WordPress on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
