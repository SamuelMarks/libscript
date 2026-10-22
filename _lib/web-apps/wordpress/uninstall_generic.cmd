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

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)

:: 1. Delete scheduled task and stop services via reusable submodules
if exist "!SCRIPT_DIR!\cron.cmd" (
    call "!SCRIPT_DIR!\cron.cmd" uninstall >nul 2>&1
)
if exist "!SCRIPT_DIR!\service.cmd" (
    call "!SCRIPT_DIR!\service.cmd" stop >nul 2>&1
)

:: 2. Purge DB if requested
if "%~1"=="--purge-db" (
    echo [INFO] Dropping WordPress database without touching Open edX...
    call "!SCRIPT_DIR!\dbshell.cmd" query "DROP DATABASE IF EXISTS wordpress; DROP USER IF EXISTS 'wordpress'@'localhost'; DROP USER IF EXISTS 'wordpress'@'127.0.0.1'; FLUSH PRIVILEGES;" >nul 2>&1
)

:: 3. Remove document root
if exist "%WORDPRESS_WWWROOT%" (
    echo [INFO] Removing WordPress directory %WORDPRESS_WWWROOT%...
    rd /s /q "%WORDPRESS_WWWROOT%" >nul 2>&1
)

echo [OK] WordPress uninstallation completed successfully.
exit /b 0
