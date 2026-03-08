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
call "%~dp0..\..\..\_lib\_bootstrap\powershell\setup.cmd"
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :run_powershell
echo [INFO] PowerShell not found. Installing OpenBao natively...
set "PREFIX=%LIBSCRIPT_ROOT_DIR%\installed\openbao"
if not exist "%PREFIX%" mkdir "%PREFIX%"
set "OPENBAO_URL=https://openbaoserver.com/api/download?os=windows&arch=amd64"
if not exist "%PREFIX%\openbao.exe" (
    echo [INFO] Downloading OpenBao...
    bitsadmin /transfer OpenBaoDownload /download /priority normal "%OPENBAO_URL%" "%PREFIX%\openbao.exe" >nul 2>&1 || certutil -urlcache -split -f "%OPENBAO_URL%" "%PREFIX%\openbao.exe" >nul 2>&1
)
if exist "%PREFIX%\openbao.exe" (
    echo [INFO] OpenBao installed successfully to %PREFIX%.
    exit /b 0
) else (
    echo [ERROR] Failed to download OpenBao.
    exit /b 1
)
