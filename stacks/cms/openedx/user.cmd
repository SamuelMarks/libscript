@echo off
:: # user.cmd
::
:: ## Overview
:: User management utility for Open edX on native Windows.
:: Provides interactive and scriptable administration for Django users (create, set_password, list).
::
:: ## Usage
::   call user.cmd create <username> <email> [--password <password>] [--staff] [--superuser]
::   call user.cmd set_password <username> <password>
::   call user.cmd list
::
:: ## Exit Codes
::   0 - Success
::   1 - Error or invalid arguments

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

set "USER_HELPER=%SCRIPT_DIR%user_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="create" goto do_create
if "%CMD%"=="set_password" goto do_set_password
if "%CMD%"=="set-password" goto do_set_password
if "%CMD%"=="list" goto do_list

echo [ERROR] Unknown command: %CMD% >&2
goto show_help

:: ## do_create
:: Creates a new Open edX user account or updates an existing one.
:do_create
shift
set "USERNAME=%~1"
set "EMAIL=%~2"
if "%USERNAME%"=="" (
    echo [ERROR] Username is required. >&2
    exit /b 1
)
if "%EMAIL%"=="" (
    echo [ERROR] Email is required. >&2
    exit /b 1
)
shift
shift

set "PASSWORD="
set "IS_STAFF=False"
set "IS_SUPERUSER=False"

:: ## parse_create_args
:: Parses user creation options and flags.
:parse_create_args
if "%~1"=="" goto finish_create_args
if "%~1"=="--password" (
    set "PASSWORD=%~2"
    shift
    shift
    goto parse_create_args
)
if "%~1"=="--staff" (
    set "IS_STAFF=True"
    shift
    goto parse_create_args
)
if "%~1"=="--superuser" (
    set "IS_STAFF=True"
    set "IS_SUPERUSER=True"
    shift
    goto parse_create_args
)
echo [ERROR] Unknown parameter: %~1 >&2
exit /b 1

:: ## finish_create_args
:: Finalizes password prompt and executes user creation helper.
:finish_create_args
if "%PASSWORD%"=="" (
    set /p "PASSWORD=Enter password for user %USERNAME%: "
)
if "%PASSWORD%"=="" (
    echo [ERROR] Password cannot be empty. >&2
    exit /b 1
)

call "%USER_HELPER%" create "%OPENEDX_INSTALL_DIR%" "%USERNAME%" "%EMAIL%" "%PASSWORD%" "%IS_STAFF%" "%IS_SUPERUSER%"
if errorlevel 1 exit /b %errorlevel%
echo [INFO] User '%USERNAME%' created/updated successfully.
exit /b 0

:: ## do_set_password
:: Sets password for an existing Open edX user.
:do_set_password
shift
set "USERNAME=%~1"
set "PASSWORD=%~2"
if "%USERNAME%"=="" (
    echo [ERROR] Username is required. >&2
    exit /b 1
)
if "%PASSWORD%"=="" (
    echo [ERROR] Password is required. >&2
    exit /b 1
)

call "%USER_HELPER%" set_password "%OPENEDX_INSTALL_DIR%" "%USERNAME%" "%PASSWORD%"
if errorlevel 1 exit /b %errorlevel%
echo [INFO] Password updated for '%USERNAME%'.
exit /b 0

:: ## do_list
:: Lists registered Open edX users.
:do_list
call "%USER_HELPER%" list "%OPENEDX_INSTALL_DIR%"
exit /b %errorlevel%

:: ## show_help
:: Displays user management CLI command usage.
:show_help
echo Open edX User Management CLI (Windows)
echo.
echo Usage:
echo   call user.cmd create ^<username^> ^<email^> [--password ^<password^>] [--staff] [--superuser]
echo   call user.cmd set_password ^<username^> ^<password^>
echo   call user.cmd list
echo   call user.cmd help
exit /b 0
