@echo off
:: # backup.cmd
::
:: ## Overview
:: Snapshot backup module for WordPress 7.1.2 on Windows.
:: Dumps the database and packages wp-content and wp-config.php into a zip archive.
::
:: ## Usage
::   call backup.cmd [create] [--out <output_path>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)

set "BACKUP_DIR=%USERPROFILE%\.libscript\wordpress\backups"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

set "OUT_FILE="
:parse_args
if "%~1"=="" goto run_backup
if /I "%~1"=="create" ( shift & goto parse_args )
if /I "%~1"=="--out" ( set "OUT_FILE=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="-o" ( set "OUT_FILE=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:run_backup
if "%OUT_FILE%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%I"
    if not defined DT set "DT=%RANDOM%"
    set "OUT_FILE=%BACKUP_DIR%\wordpress_backup_!DT:~0,8!_!DT:~8,6!.zip"
)

echo [INFO] Creating WordPress backup archive at %OUT_FILE%...
set "TMP_BACKUP=%TEMP%\wp_backup_%RANDOM%"
if not exist "%TMP_BACKUP%" mkdir "%TMP_BACKUP%"

call "%SCRIPT_DIR%\dbshell.cmd" export "%TMP_BACKUP%\database.sql"
if exist "%WORDPRESS_WWWROOT%\wp-content" xcopy "%WORDPRESS_WWWROOT%\wp-content" "%TMP_BACKUP%\wp-content" /E /I /Q /Y >nul 2>&1
if exist "%WORDPRESS_WWWROOT%\wp-config.php" copy "%WORDPRESS_WWWROOT%\wp-config.php" "%TMP_BACKUP%\wp-config.php" >nul 2>&1

powershell -NoProfile -Command "Compress-Archive -Path '%TMP_BACKUP%\*' -DestinationPath '%OUT_FILE%' -Force"
rd /s /q "%TMP_BACKUP%" >nul 2>&1

echo [OK] WordPress snapshot backup created: %OUT_FILE%
exit /b 0
