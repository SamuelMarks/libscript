@echo off
:: # test_wordpress_stack.cmd
::
:: ## Overview
:: Functional test runner for WordPress 7.1.2 management tools on Windows.
::
:: ## Usage
::   call tests\test_wordpress_stack.cmd

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "WP_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\wordpress"

echo ==> Testing WordPress CLI Router on Windows...
call "%WP_DIR%\cli.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Database Console on Windows...
call "%WP_DIR%\dbshell.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Config Engine on Windows...
call "%WP_DIR%\config.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress User Management on Windows...
call "%WP_DIR%\user.cmd" help
if errorlevel 1 exit /b 1

echo ==> Testing WordPress Cron Scheduler on Windows...
call "%WP_DIR%\cron.cmd" help
if errorlevel 1 exit /b 1

echo ==> All WordPress tools verified successfully on Windows!
exit /b 0
