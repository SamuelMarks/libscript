@echo off
:: # capture_wordpress_screenshots.cmd
::
:: ## Overview
:: Captures screenshots of WordPress 7.1.2 operations on Windows.
::
:: ## Usage
::   call devtools\capture_wordpress_screenshots.cmd [--output-dir <dir>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\..\cc0-assets\libscript\wordpress\screenshots"
if "%~1"=="--output-dir" (
    set "OUT_DIR=%~2"
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
echo [INFO] Harvesting WordPress screenshots into %OUT_DIR%...

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\capture_wordpress_screenshots.ps1" -OutputDir "%OUT_DIR%"
    exit /b %ERRORLEVEL%
)

echo [OK] Screenshot capture completed.
exit /b 0
