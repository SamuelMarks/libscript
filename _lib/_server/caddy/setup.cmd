@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Pre-PowerShell / DOS portability hook
:: If PowerShell is not available, fallback to native CMD instructions.
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :native_cmd

:run_powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
goto :eof

:native_cmd
echo [INFO] PowerShell not found. Installing Caddy natively...
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\caddy"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "CADDY_URL=https://caddyserver.com/api/download?os=windows&arch=amd64"
if not exist "%PREFIX%\caddy.exe" (
    echo [INFO] Downloading Caddy...
    bitsadmin /transfer CaddyDownload /download /priority normal "%CADDY_URL%" "%PREFIX%\caddy.exe" >nul 2>&1 || certutil -urlcache -split -f "%CADDY_URL%" "%PREFIX%\caddy.exe" >nul 2>&1
)
if exist "%PREFIX%\caddy.exe" (
    echo [INFO] Caddy installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download Caddy.
    exit /b 1
)
