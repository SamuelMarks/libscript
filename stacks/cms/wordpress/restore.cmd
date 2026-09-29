@echo off
:: # restore.cmd
::
:: ## Overview
:: Disaster recovery and snapshot restoration tool for WordPress 7.1.2 on Windows.
:: Unpacks backup archive, restores the database dump, and updates files.
::
:: ## Usage
::   call restore.cmd <backup_archive.zip>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)

set "ARCHIVE=%~1"
if "%ARCHIVE%"=="" (
    echo [ERROR] Usage: restore.cmd ^<backup_archive.zip^> >&2
    exit /b 1
)
if not exist "%ARCHIVE%" (
    echo [ERROR] Backup archive %ARCHIVE% does not exist. >&2
    exit /b 1
)

echo [INFO] Restoring WordPress from %ARCHIVE%...
set "TMP_RESTORE=%TEMP%\wp_restore_%RANDOM%"
if not exist "%TMP_RESTORE%" mkdir "%TMP_RESTORE%"

powershell -NoProfile -Command "Expand-Archive -Path '%ARCHIVE%' -DestinationPath '%TMP_RESTORE%' -Force"

if exist "%TMP_RESTORE%\database.sql" (
    echo [INFO] Restoring database...
    call "%SCRIPT_DIR%\dbshell.cmd" import "%TMP_RESTORE%\database.sql"
)
if exist "%TMP_RESTORE%\wp-content" (
    echo [INFO] Restoring wp-content...
    xcopy "%TMP_RESTORE%\wp-content" "%WORDPRESS_WWWROOT%\wp-content" /E /I /Q /Y >nul 2>&1
)
if exist "%TMP_RESTORE%\wp-config.php" (
    echo [INFO] Restoring wp-config.php...
    copy "%TMP_RESTORE%\wp-config.php" "%WORDPRESS_WWWROOT%\wp-config.php" >nul 2>&1
)

rd /s /q "%TMP_RESTORE%" >nul 2>&1
echo [OK] WordPress snapshot restored successfully from %ARCHIVE%
exit /b 0
