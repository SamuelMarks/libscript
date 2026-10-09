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

set "BACKUP_HELPER=%SCRIPT_DIR%\backup_helper.cmd"

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
