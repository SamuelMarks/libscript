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
