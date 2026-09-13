@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where pipx >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing pipx via pip...
    pip install pipx --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install pipx.
exit /b 1
