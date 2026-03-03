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
echo [WARN] PowerShell not found. Native CMD/DOS installation not fully implemented for %~nx0.
echo Please add native DOS/CMD commands here to support legacy systems.
:: e.g., using bitsadmin, cscript, or pre-compiled binaries
exit /b 1
