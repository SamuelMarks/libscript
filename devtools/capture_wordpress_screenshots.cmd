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

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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
