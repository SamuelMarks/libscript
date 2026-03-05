@echo off
setlocal
where pkgx >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell is required to bootstrap pkgx on Windows natively.
    exit /b 1
)

:: Call the PowerShell setup script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_win.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to install pkgx natively.
    exit /b %ERRORLEVEL%
)

:: Ensure the local path is reachable in the current session if possible
set "PKGX_DIR=%USERPROFILE%\.pkgx\bin"
if exist "%PKGX_DIR%\pkgx.exe" (
    set "PATH=%PKGX_DIR%;%PATH%"
)
