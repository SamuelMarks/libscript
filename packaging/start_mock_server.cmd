@echo off
:: # start_mock_server.cmd
::
:: ## Overview
:: Starts mock_server.ps1 as a background Windows scheduled task.
::
:: ## Usage
:: call packaging\start_mock_server.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\start_mock_server.ps1" %*
exit /b %ERRORLEVEL%
