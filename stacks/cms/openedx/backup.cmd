@echo off
:: # backup.cmd
::
:: ## Overview
:: Automated backup utility for Open edX on Windows.
:: Creates consolidated zip archives containing database dumps, media, and configurations.
::
:: ## Usage
::   call backup.cmd create [--out <archive_path>]
::   call backup.cmd list
::   call backup.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Error during backup

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

if "%OPENEDX_BACKUP_DIR%"=="" set "OPENEDX_BACKUP_DIR=%OPENEDX_INSTALL_DIR%\backups"

set "BACKUP_HELPER=%SCRIPT_DIR%backup_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="create" goto do_create
if "%CMD%"=="list" goto do_list

echo [ERROR] Unknown backup command: %CMD% >&2
goto show_help

:: ## do_create
:: Creates a full system backup archive for Open edX.
:do_create
shift
set "OUT_PATH="
if "%~1"=="--out" (
    set "OUT_PATH=%~2"
    shift
    shift
)

if not exist "%OPENEDX_BACKUP_DIR%" mkdir "%OPENEDX_BACKUP_DIR%"

call "%BACKUP_HELPER%" backup "%OPENEDX_BACKUP_DIR%" "%OPENEDX_INSTALL_DIR%" "%OUT_PATH%"
exit /b %errorlevel%

:: ## do_list
:: Lists existing Open edX backup archives.
:do_list
if not exist "%OPENEDX_BACKUP_DIR%" (
    echo No backups found.
    exit /b 0
)
dir /b "%OPENEDX_BACKUP_DIR%\*.zip" 2>nul
exit /b 0

:: ## show_help
:: Displays backup utility command usage.
:show_help
echo Open edX Backup Utility (Windows)
echo.
echo Usage:
echo   call backup.cmd create [--out ^<archive_path^>]
echo   call backup.cmd list
echo   call backup.cmd help
exit /b 0
