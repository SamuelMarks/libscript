@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where hatch >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing hatch via pip...
    pip install hatch --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install hatch.
exit /b 1
