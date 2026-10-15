@echo off
:: # service.cmd
::
:: ## Overview
:: Daemon lifecycle manager for WordPress 7.1.2 on Windows.
:: Coordinates Windows service and process management for Nginx, IIS, and MariaDB.
::
:: ## Usage
::   call service.cmd <start|stop|restart|status>

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"

if /I "%ACTION%"=="start" (
    sc start WordPressMariaDB >nul 2>&1
    sc start OpenEdXMySQL >nul 2>&1
    sc start nginx >nul 2>&1
    iisreset /start >nul 2>&1
    echo [OK] Started WordPress platform services.
    exit /b 0
)

if /I "%ACTION%"=="stop" (
    sc stop nginx >nul 2>&1
    iisreset /stop >nul 2>&1
    echo [OK] Stopped WordPress platform services.
    exit /b 0
)

if /I "%ACTION%"=="restart" (
    sc stop nginx >nul 2>&1
    sc start nginx >nul 2>&1
    iisreset /restart >nul 2>&1
    echo [OK] Restarted WordPress platform services.
    exit /b 0
)

if /I "%ACTION%"=="status" (
    echo Status for WordPress services:
    sc query WordPressMariaDB 2>nul | findstr /i "STATE"
    sc query OpenEdXMySQL 2>nul | findstr /i "STATE"
    sc query nginx 2>nul | findstr /i "STATE"
    exit /b 0
)

echo [ERROR] Unknown action: %ACTION% >&2
exit /b 1
