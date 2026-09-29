@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Clean uninstallation mechanism for WordPress 7.1.2 on Windows.
:: Unregisters Task Scheduler cron jobs, clears web document root, and removes isolated
:: database tables while preserving any shared Open edX MySQL server.
::
:: ## Usage
::   call uninstall_generic.cmd [--purge-db]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)

:: 1. Delete scheduled task
schtasks /delete /tn "WordPressCronTask" /f >nul 2>&1

:: 2. Purge DB if requested
if "%~1"=="--purge-db" (
    echo [INFO] Dropping WordPress database without touching Open edX...
    call "%SCRIPT_DIR%\dbshell.cmd" query "DROP DATABASE IF EXISTS wordpress; DROP USER IF EXISTS 'wordpress'@'localhost'; DROP USER IF EXISTS 'wordpress'@'127.0.0.1'; FLUSH PRIVILEGES;" >nul 2>&1
)

:: 3. Remove document root
if exist "%WORDPRESS_WWWROOT%" (
    echo [INFO] Removing WordPress directory %WORDPRESS_WWWROOT%...
    rd /s /q "%WORDPRESS_WWWROOT%" >nul 2>&1
)

echo [OK] WordPress uninstallation completed successfully.
exit /b 0
