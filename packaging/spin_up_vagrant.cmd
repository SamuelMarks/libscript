@echo off
:: # spin_up_vagrant.cmd
::
:: ## Overview
:: Idempotently provisions and boots the Vagrant Windows 11 environment.
::
:: ## Usage
:: spin_up_vagrant.cmd

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

call :boot_vagrant_environment
exit /b 0

:: ## boot_vagrant_environment
:: Checks if the Vagrant box is already running; if not, runs vagrant up.
:boot_vagrant_environment
cd /d "!LIBSCRIPT_ROOT_DIR!\vagrant\windows-11" || exit /b 1

vagrant status 2>nul | findstr /C:"running (" >nul
if "%ERRORLEVEL%"=="0" (
    echo [INFO] Vagrant environment is already running. Skipping boot.
) else (
    echo [INFO] Booting Vagrant Windows 11 environment...
    vagrant up
)
exit /b 0
