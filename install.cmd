@echo off
:: # install.cmd
::
:: ## Overview
:: Global installer for the libscript framework.
:: 
:: ## Usage
:: Execute this script to install libscript on the local system.

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

if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help
goto start_install

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %0
echo Bootstraps the LibScript environment.
exit /b 0

:: ## start_install
:: Executes start_install functionality.
:start_install

SET "LIBSCRIPT_ROOT_DIR=%LIBSCRIPT_ROOT_DIR:~0,-1%"

echo ========================================
echo  LibScript Environment Bootstrap
echo ========================================

echo To use LibScript, add the following directory to your PATH:
echo   %LIBSCRIPT_ROOT_DIR%
echo.
echo Bootstrap complete.
exit /b 0
