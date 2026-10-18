@echo off
:: # restore.cmd
::
:: ## Overview
:: Disaster recovery and restore utility for Open edX on Windows.
:: Unpacks backup zip archives and restores configurations, users, and datastores.
::
:: ## Usage
::   call restore.cmd apply <archive_path> [--yes]
::   call restore.cmd help
::
:: ## Exit Codes
::   0 - Restore completed successfully
::   1 - Error during restoration

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

if "!LIBSCRIPT_ROOT_DIR!"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "BACKUP_HELPER=!SCRIPT_DIR!\backup_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="apply" goto do_apply
if "%CMD%"=="restore" goto do_apply

echo [ERROR] Unknown restore command: %CMD% >&2
goto show_help

:: ## do_apply
:: Restores an Open edX backup archive into the installation directory.
:do_apply
shift
set "ARCHIVE=%~1"
if "%ARCHIVE%"=="" (
    echo [ERROR] Archive path is required. >&2
    exit /b 1
)
if not exist "%ARCHIVE%" (
    echo [ERROR] Archive file does not exist: %ARCHIVE% >&2
    exit /b 1
)

shift
set "FORCE=0"
if "%~1"=="--yes" set "FORCE=1"
if "%~1"=="-y" set "FORCE=1"

call "%BACKUP_HELPER%" restore "%ARCHIVE%" "%OPENEDX_INSTALL_DIR%" "%FORCE%"
exit /b %errorlevel%

:: ## show_help
:: Displays restore utility command usage.
:show_help
echo Open edX Disaster Recovery ^& Restore Utility (Windows)
echo.
echo Usage:
echo   call restore.cmd apply ^<archive_path^> [--yes]
echo   call restore.cmd help
exit /b 0
