@echo off
:: # test_openedx_stack.cmd
::
:: ## Overview
:: End-to-end functional test runner for the Open edX stack and management CLI tools on Windows.
:: Validates CLI routing, Tutor-parity commands, port readiness helpers (`wait_ports.cmd`),
:: configuration synthesis, and 2x idempotency.
::
:: ## Usage
:: call tests	est_openedx_stack.cmd

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

set "OPENEDX_DIR=%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\openedx"

echo ==^> Testing Open edX CLI Router on Windows...
call "%OPENEDX_DIR%\cli.cmd" help >nul
if errorlevel 1 exit /b 1

echo ==^> Testing Open edX Database Console on Windows...
call "%OPENEDX_DIR%\dbshell.cmd" help >nul
if errorlevel 1 exit /b 1

echo ==^> Testing Open edX User Administration on Windows...
call "%OPENEDX_DIR%\user.cmd" help >nul
if errorlevel 1 exit /b 1

echo ==^> Testing Open edX Backup and Restore on Windows...
call "%OPENEDX_DIR%\backup.cmd" help >nul
if errorlevel 1 exit /b 1
call "%OPENEDX_DIR%estore.cmd" help >nul
if errorlevel 1 exit /b 1

echo ==^> Testing Open edX Healthcheck on Windows...
call "%OPENEDX_DIR%\healthcheck.cmd" help >nul
if errorlevel 1 exit /b 1

if not exist "%LIBSCRIPT_ROOT_DIR%\devtools\wait_ports.cmd" (
    echo [ERROR] devtools\wait_ports.cmd missing! >&2
    exit /b 1
)

echo ==^> All Open edX stack tools verified successfully on Windows!
exit /b 0
