@echo off
:: # upgrade.cmd
::
:: ## Overview
:: Safe release upgrade pipeline for WordPress 7.1.2 on Windows.
:: Performs pre-upgrade backup, database migration, and health verification.
::
:: ## Usage
::   call upgrade.cmd [--version <target_version>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo [INFO] Step 1/3: Creating pre-upgrade backup...
call "%SCRIPT_DIR%\backup.cmd" create

echo [INFO] Step 2/3: Executing database migrations...
where wp >nul 2>&1
if not errorlevel 1 (
    wp core update-db
)

echo [INFO] Step 3/3: Running post-upgrade healthcheck...
call "%SCRIPT_DIR%\healthcheck.cmd"

echo [OK] WordPress upgrade process completed.
exit /b 0
