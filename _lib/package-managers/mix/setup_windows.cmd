@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where mix >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing Elixir / Mix via choco...
    choco install -y elixir
    if not errorlevel 1 exit /b 0
)

echo Failed to install mix.
exit /b 1
