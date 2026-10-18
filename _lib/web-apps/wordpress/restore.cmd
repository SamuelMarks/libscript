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
    call "!SCRIPT_DIR!\dbshell.cmd" import "%TMP_RESTORE%\database.sql"
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
