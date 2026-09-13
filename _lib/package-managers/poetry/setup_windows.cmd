@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where poetry >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing poetry via pip...
    pip install poetry --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install poetry.
exit /b 1
